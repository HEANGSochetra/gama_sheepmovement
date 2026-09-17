/**
* Name: SheepMovement
* Based on the internal empty template. 
* Author: heangsochetra
* Tags: 
*/


model SheepMovement

/* Insert your model definition here */

global {
	int number_of_sheep <- 20;
	int number_of_vegetable <- 0;
	int number_of_obstacle <- 0;
	int number_of_dog <- 0;
	float dog_speed <- 1.5;
	bool export_time_series <- false;
	geometry shape <- square(100#m);
	point start_point <- {10, 50};
	
	float min_perception_distance <- 35#m;
	float max_perception_distance <- 50#m;

	// Measurements used by the monitors, charts and batch experiment.
	float mean_distance_travelled <- 0.0;
	float mean_nearest_neighbour_distance <- 0.0;
	int total_obstacle_encounters <- 0;
	int trampled_cells <- 0;
	int total_trampling_events <- 0;
	float trampled_area_percent <- 0.0;
	float mean_trampling_intensity <- 0.0;
	
	init {		
		create vegetable number: number_of_vegetable {
			location <- any_location_in(shape);
		}
		create sheep number: number_of_sheep {
//		    location <- {rnd(5, 15),rnd(40, 60)};
			location <- one_of(shape);
		    sheep_target <- one_of(vegetable);
		}
		create obstacle number: number_of_obstacle {
			location <- any_location_in(shape);
		}
		create dog number: number_of_dog {
			location <- any_location_in(shape);
		}

		if export_time_series {
			save ["cycle", "obstacles", "mean_distance_m", "mean_neighbour_distance_m",
				"obstacle_encounters", "trampled_cells", "trampled_area_percent",
				"mean_trampling_intensity"]
				to: "sheep_movement_timeseries.csv" format: "csv"
				rewrite: true header: false;
		}

	}

	reflex collect_statistics {
		if !empty(sheep) {
			mean_distance_travelled <- mean(sheep collect each.total_distance);
			mean_nearest_neighbour_distance <- mean(sheep collect each.nearest_neighbour_distance);
			total_obstacle_encounters <- sum(sheep collect each.obstacle_encounters);
		}

		trampled_area_percent <- 100.0 * trampled_cells / length(landscape);
		mean_trampling_intensity <- trampled_cells = 0
			? 0.0
			: total_trampling_events / trampled_cells;

		if export_time_series {
			save [cycle, number_of_obstacle, mean_distance_travelled,
				mean_nearest_neighbour_distance, total_obstacle_encounters,
				trampled_cells, trampled_area_percent, mean_trampling_intensity]
				to: "sheep_movement_timeseries.csv" format: "csv"
				rewrite: false header: false;
		}
	}
}

grid landscape
    width: 100#m
    height: 100#m
    neighbors: 8 {
    int tramping <- 0;
    reflex update_color {
        if tramping = 0 {
            color <- rgb(235, 245, 225, 0);
        }
        else if tramping < 5 {
            color <- rgb(255, 245, 180, 80);
        }
        else if tramping < 15 {
            color <- rgb(255, 195, 100, 110);
        }
        else if tramping < 30 {
            color <- rgb(245, 130, 50, 140);
        }
        else {
            color <- rgb(190, 50, 30, 170);
        }
    }
}

species vegetable {
//	init {
//		location <- {0,0};
//	}
	
	aspect default {
        draw file("images/grass.png")
            size: 10#m;
    }
}

species obstacle {
    string obstacle_type <- one_of(["rock", "tree"]);
    float obstacle_size <- rnd(4.0, 6.0);
    aspect default {
        if obstacle_type = "rock" {
            draw file("images/rock.png")
                at: location
                size: obstacle_size * 2;
        }
        else {
            draw file("images/tree.png")
                at: location
                size: obstacle_size * 2;
        }
    }
}

species dog skills:[moving] {
	reflex chase_sheep when: !empty(sheep) {
		sheep nearest_sheep <- sheep(sheep closest_to self);
		speed <- dog_speed;
		do goto target: nearest_sheep.location;
	}

	reflex search_when_no_sheep when: empty(sheep) {
		speed <- dog_speed;
		do wander amplitude: 120.0;
	}

	aspect default {
        draw file("images/dog.png")
            size: 3#m;
    }
}

species sheep skills:[moving] {
	bool reached_food <- false;
	float perception_dist <- rnd(min_perception_distance, max_perception_distance);
	float separation_dist <- 2#m;
	
	float obstacle_perception_dist <- 15#m;
	float dog_perception_dist <- 10#m;
	bool avoiding_obstacle <- false;
	bool was_near_obstacle <- false;
	int obstacle_encounters <- 0;
	point previous_location <- location;
	float total_distance <- 0.0;
	float nearest_neighbour_distance <- 0.0;
	
	vegetable sheep_target;
	
	// Obstacle avoidance has priority over ordinary movement and herding.
	reflex avoid_obstacles {
		list<obstacle> nearby_obstacles <- obstacle at_distance obstacle_perception_dist;
		avoiding_obstacle <- !empty(nearby_obstacles);
		if avoiding_obstacle {
			obstacle nearest_obstacle <- obstacle(nearby_obstacles closest_to self);
			point away_from_obstacle <- location + (location - nearest_obstacle.location);
			do goto target: away_from_obstacle;
			if !was_near_obstacle {
				obstacle_encounters <- obstacle_encounters + 1;
			}
		}
		was_near_obstacle <- avoiding_obstacle;
	}

	reflex move when: (sheep_target != nil) and !avoiding_obstacle {
	    do goto target: sheep_target;
	}
	
	reflex moverandom when: (sheep_target = nil) and !avoiding_obstacle {
	    do wander amplitude: 60.0;
	}
	
	reflex see_dog {
	    list<dog> nearby_dog <-
	        dog at_distance dog_perception_dist;
	    if !empty(nearby_dog) {
	        dog nearest_dog <-
	            dog(nearby_dog closest_to self);
	        point away_from_dog <-
	            location + (location - nearest_dog.location);
	        do goto target: away_from_dog;
	    }
	}
	
	reflex herd_behavior when: !avoiding_obstacle {

        list<sheep> nearby <-
            (sheep at_distance perception_dist) - self;
        if !empty(nearby) {
            sheep nearest_sheep <-
                sheep(nearby closest_to self);

            float distance_to_nearest <-
                self distance_to nearest_sheep;
                
            if distance_to_nearest < separation_dist {
                point away_direction <-
                    location + (location - nearest_sheep.location);
                do goto target: away_direction;
            }
            else {
                do goto target: nearest_sheep;
            }
        }
    }
  
	
    reflex record_tramping {
		total_distance <- total_distance + (previous_location distance_to location);
		previous_location <- location;
		list<sheep> other_sheep <- sheep - self;
		nearest_neighbour_distance <- empty(other_sheep)
			? 0.0
			: self distance_to (other_sheep closest_to self);

        if !reached_food {
            landscape current_cell <- landscape(location);
            if current_cell != nil {
				if current_cell.tramping = 0 {
					trampled_cells <- trampled_cells + 1;
				}
                current_cell.tramping <-
                    current_cell.tramping + 1;
				total_trampling_events <- total_trampling_events + 1;
            }
        }
    }
    
    

    aspect default {
        draw file("images/sheep.png")
            size: 3#m;
    }
 
}

experiment "Sheep Movement" type:gui {
	parameter "Number of sheep"
        var: number_of_sheep
        min: 20
        max: 100
        step: 1;
	parameter "Number of vegetable"
        var: number_of_vegetable
        min: 0
        max: 10
        step: 1;
	parameter "Number of Obstacle"
        var: number_of_obstacle
        min: 0
        max: 30
        step: 1;
	parameter "Number of Dog"
        var: number_of_dog
        min: 0
        max: 10
        step: 1;
	parameter "Dog chase speed"
		var: dog_speed
		min: 0.5
		max: 3.0
		step: 0.1;
	parameter "Export per-cycle CSV"
		var: export_time_series;
	output{
		display "My Environment" {
            graphics "background" {
                draw file("images/bg.jpg")
                    at: {50#m, 50#m}
                    size: {100#m, 100#m};
            }
			grid landscape
            	transparency: 0.35;
			species sheep;
			species vegetable;
			species obstacle;
			species dog;
		}
		display "Movement and flock charts" {
			chart "Mean cumulative distance travelled (m)" type: series {
				data "Mean distance" value: mean_distance_travelled color: #blue;
			}
			chart "Mean nearest-neighbour distance (m)" type: series {
				data "Flock spacing" value: mean_nearest_neighbour_distance color: #orange;
			}
		}
		display "Obstacle and landscape charts" {
			chart "Cumulative obstacle encounters" type: series {
				data "Encounters" value: total_obstacle_encounters color: #red;
			}
			chart "Trampling impact" type: series {
				data "Trampled area (%)" value: trampled_area_percent color: #darkgreen;
				data "Mean intensity" value: mean_trampling_intensity color: #magenta;
			}
		}
		monitor "Obstacle treatment" value: number_of_obstacle;
		monitor "Mean distance travelled (m)" value: mean_distance_travelled;
		monitor "Mean flock spacing (m)" value: mean_nearest_neighbour_distance;
		monitor "Obstacle encounters" value: total_obstacle_encounters;
		monitor "Trampled area (%)" value: trampled_area_percent;
	}
}

// Runs four obstacle treatments (none, few, medium and many), ten times each.
// Open obstacle_comparison_results.csv after the experiment finishes to analyse
// one row per replicate and obstacle treatment.
experiment "Obstacle comparison (batch)" type: batch repeat: 10 keep_seed: true
	until: (cycle >= 500) {
	parameter "Number of sheep" var: number_of_sheep <- 40;
	parameter "Number of vegetables" var: number_of_vegetable <- 0;
	parameter "Number of dogs" var: number_of_dog <- 0;
	parameter "Obstacle treatment (0/5/15/30)"
		var: number_of_obstacle among: [0, 5, 15, 30];

	method exploration
		outputs: [mean_distance_travelled, mean_nearest_neighbour_distance,
			total_obstacle_encounters, trampled_cells, trampled_area_percent,
			mean_trampling_intensity]
		results: "obstacle_comparison_results.csv";
}
