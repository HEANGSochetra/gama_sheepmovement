model sheep_movement
global {
    geometry shape <- square(100);
    int number_of_sheep <- 40;
    int number_of_obstacles <- 10;
    int number_of_dogs <- 1;
    int number_of_fences <- 5;
    int number_of_targets <- 3;
    int number_of_high_hills <- 2;
    float sheep_speed <- 0.8;
    float high_hill_radius <- 12.0;
    float dog_fear_distance <- 20.0;
    float perception_distance <- 8.0;
    float separation_distance <- 2.0;
    float herd_probability <- 0.60;
    point start_point <- {10, 50};
    init {
        create obstacle number: number_of_obstacles {
            location <- {
                rnd(30, 70),
                rnd(15, 85)
            };
        }
        create fence number: number_of_fences {
            location <- {
                rnd(25, 75),
                rnd(15, 85)
            };
        }
        create grass_target number: number_of_targets {
            location <- {
                rnd(82, 95),
                rnd(10, 90)
            };
        }
        create high_hill number: number_of_high_hills {
            location <- {
                rnd(25, 75),
                rnd(15, 85)
            };
        }
        create sheep number: number_of_sheep {
            location <- {rnd(5, 15),rnd(40, 60)};
            speed <- sheep_speed;
        }
        create dog number: number_of_dogs {
            location <- {rnd(2, 8), rnd(40, 60)};
            speed <- sheep_speed * 2.0;
        }
    }
}
grid landscape
    width: 100
    height: 100
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
species sheep skills: [moving] {
    bool reached_food <- false;
    grass_target destination <- nil;
    float distance_to_food <- 0.0;
    reflex move {
        if !reached_food {
            destination <- grass_target closest_to self;
            if destination != nil {
                distance_to_food <-
                    location distance_to destination.location;
            }
        }
        list<sheep> neighbours <-
            (sheep at_distance perception_distance)
            where (each != self);
        list<sheep> too_close <-
            (sheep at_distance separation_distance)
            where (each != self);
        list<obstacle> nearby_obstacles <-
            obstacle at_distance 4.0;
        list<fence> nearby_fences <- fence at_distance 6.0;
        list<high_hill> nearby_high_hills <-
            high_hill at_distance (high_hill_radius + 2.0);
        list<dog> nearby_dogs <-
            dog at_distance dog_fear_distance;
        if reached_food {
            speed <- 0.0;
        }
        else if destination = nil {
            speed <- 0.0;
        }
        else if distance_to_food <= 3.0 {
            reached_food <- true;
            speed <- 0.0;
        }
        else if !empty(nearby_fences) {
            speed <- sheep_speed;
            do wander amplitude: 150.0;
        }
        else if !empty(nearby_high_hills) {
            speed <- sheep_speed;
            high_hill avoided_high_hill <-
                nearby_high_hills closest_to self;
            float high_hill_detour_y <-
                avoided_high_hill.location.y +
                high_hill_radius + 3.0;
            if location.y < avoided_high_hill.location.y {
                high_hill_detour_y <-
                    avoided_high_hill.location.y -
                    high_hill_radius - 3.0;
            }
            point high_hill_detour <- {
                avoided_high_hill.location.x,
                high_hill_detour_y
            };
            do goto target: high_hill_detour;
        }
        else if !empty(nearby_obstacles) {
            speed <- sheep_speed;
            do wander amplitude: 120.0;
        }
        else if !empty(nearby_dogs) {
            speed <- sheep_speed * 1.5;
            do goto target: destination.location;
        }
        else {
            speed <- sheep_speed;
            if !empty(too_close) {
                do wander amplitude: 90.0;
            }
            else if (!empty(neighbours)) and flip(herd_probability) {
                sheep friend <- neighbours closest_to self;
                if friend != nil {
                    do goto target: friend.location;
                }
            }
            else {
                do goto target: destination.location;
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
            at: location
            size: 3;
    }
}
species dog skills: [moving] {
    reflex herd_sheep {
        speed <- sheep_speed * 2.0;
        list<sheep> sheep_to_herd <-
            sheep where (!each.reached_food);
        grass_target dog_target <- grass_target closest_to self;
        list<fence> nearby_fences <- fence at_distance 6.0;
        list<obstacle> nearby_obstacles <-
            obstacle at_distance 4.0;
        if empty(sheep_to_herd) {
            if (dog_target != nil) and
                    ((location distance_to dog_target.location) > 3.0) {
                do goto target: dog_target.location;
            }
            else {
                speed <- 0.0;
            }
        }
        else if !empty(nearby_fences) {
            do wander amplitude: 150.0;
        }
        else if !empty(nearby_obstacles) {
            do wander amplitude: 120.0;
        }
        else {
            sheep lagging_sheep <-
                sheep_to_herd with_max_of each.distance_to_food;
            do goto target: lagging_sheep.location;
        }
    }
    aspect default {
        draw file("images/dog.png")
            at: location
            size: 4;
    }
}
species grass_target {
    aspect default {
        draw file("images/grass.png")
            at: location
            size: 7.0;
    }
}
species high_hill {
    aspect default {
        draw file("images/hill.png")
            at: location
            size: high_hill_radius * 2.0;
    }
}
species fence {
    float fence_angle <- one_of([0.0, 90.0]);
    aspect default {
        draw file("images/fence.png")
            at: location
            size: 8.0
            rotate: fence_angle;
    }
}
species obstacle {
    string obstacle_type <- one_of(["rock", "tree"]);
    float obstacle_size <- rnd(2.0, 4.0);
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
experiment sheep_experiment type: gui {
    parameter "Number of sheep"
        var: number_of_sheep
        min: 5
        max: 100
        step: 5;
    parameter "Number of obstacles"
        var: number_of_obstacles
        min: 0
        max: 30
        step: 1;
    parameter "Number of dogs"
        var: number_of_dogs
        min: 0
        max: 5
        step: 1;
    parameter "Number of fences"
        var: number_of_fences
        min: 0
        max: 20
        step: 1;
    parameter "Number of targets"
        var: number_of_targets
        min: 1
        max: 10
        step: 1;
    parameter "Number of High Hill"
        var: number_of_high_hills
        min: 0
        max: 100
        step: 1;
    parameter "High Hill radius"
        var: high_hill_radius
        min: 5.0
        max: 20.0
        step: 1.0;
    parameter "Sheep speed"
        var: sheep_speed
        min: 0.2
        max: 2.0
        step: 0.1;
    parameter "Perception distance"
        var: perception_distance
        min: 2.0
        max: 15.0
        step: 1.0;
    parameter "Separation distance"
        var: separation_distance
        min: 0.5
        max: 5.0
        step: 0.5;
    parameter "Herd probability"
        var: herd_probability
        min: 0.0
        max: 1.0
        step: 0.05;
    output {
        display "Sheep Movement" {
            graphics "background" {
                draw file("images/bg.jpg")
                    at: {50, 50}
                    size: {100, 100};
            }
            grid landscape;
            species high_hill;
            species obstacle;
            species fence;
            species grass_target;
            species sheep;
            species dog;
            graphics "markers" {
                draw file("images/flag.png")
                    at: start_point
                    size: 7.0;
            }
        }
    }
}
