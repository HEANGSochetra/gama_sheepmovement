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
	geometry shape <- square(100#m);
	point start_point <- {10, 50};
	
	float min_perception_distance <- 35#m;
	float max_perception_distance <- 50#m;
	
	init {		
		create vegetable number: number_of_vegetable {
			location <- any_location_in(shape);
		}
		create sheep number: number_of_sheep {
//		    location <- {rnd(5, 15),rnd(40, 60)};
			location <- one_of(shape);
		    sheep_target <- one_of(vegetable);
		}
		create obstacle number: number_of_obstacle ;
		create dog number: number_of_dog;

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
            size: 5#m;
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
	reflex move {
		do wander amplitude: 120;
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
	
	int obsticle_perception_dist <- 15#m;
	int dog_perception_dist <- 10#m; 
	
	vegetable sheep_target;
	
	reflex move when: sheep_target != nil {
        list<obstacle> nearby_obstacle <- obstacle at_distance obsticle_perception_dist;
        
        obstacle ob <- one_of(obstacle);
	
		if (ob != nil) and ((self distance_to ob) <= obsticle_perception_dist) {
		    do wander amplitude: 120.0;
		}
//        if (nearby_obstacle != nil){
//        	do wander amplitude: 120.0;
//        }
            
	    do goto target: sheep_target;
	}
	
	reflex moverandom when: sheep_target = nil {
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
	
	reflex herd_behavior {

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
        if !reached_food {
            landscape current_cell <- landscape(location);
            if current_cell != nil {
                current_cell.tramping <-
                    current_cell.tramping + 1;
            }
        }
    }
    
    

    aspect default {
        draw file("images/sheep.png")
            size: 3#m;
    }
 
}

experiment "Sheep Movement" {
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
        max: 10
        step: 1;
	parameter "Number of Dog"
        var: number_of_dog
        min: 0
        max: 10
        step: 1;
	output{
		display "My Environment" {
			grid landscape;
			species sheep;
			species vegetable;
			species obstacle;
			species dog;
		}
	}
}

