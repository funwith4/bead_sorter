echo(version=version());

arc_radius = 50;
rotator_height = 7;
bead_hole_radius = 4;
bead_hole_to_edge = 10;
bead_hole_angle = 15;
sensor_angle = 30;
entry_angle = 60;
structural_screw_hole_radius = 2;
structural_screw_hole_to_edge = 10;
structural_screw_spacing = 20;
servo_screw_hole_radius = 1;
servo_screw_hole_to_edge = 10;
servo_screw_spacing = 12.5;
servo_screw_height = 10;
stepper_motor_shaft_hole_height = 8;  // 5mm measured.
guide_length = 94;
guide_od = 15;
guide_id = 10;
guide_pivot_offset = 5;
support_width = 10;
support_height = 30;
support_length = 50;
support_drop = 25;
slide_angle = 30;
support_straw_cutout_height = support_length;
wall_width = 2.5;
drop_y = 140/2-(bead_hole_radius+wall_width);
tr_radius = 3.75;  // 1/4" (7m) diameter threaded rod, 3.5 was too tight -- was good for locking on threads.
tr_distance = 116;
epsilon = 0.01;  // Enough to avoid z-fighting.

// Previously, before bringing it in to fit on the bed.
// drop_y=guide_length*0.75-guide_pivot_offset;
// guide_length=100;


module pivot_on_arc_axis(d) {
    x_offset = arc_radius - bead_hole_to_edge;
    translate([-x_offset, 0, 0])
        rotate([0, 0, d])
            translate([+x_offset, 0, 0])
                children();
}

module bead_hole_pattern() {
  cylinder(rotator_height, bead_hole_radius, bead_hole_radius, center=true);
}

module structural_screw_hole_pattern() {
  cylinder(rotator_height, structural_screw_hole_radius, structural_screw_hole_radius, center=true);
}

module servo_screw_hole_pattern() {
  cylinder(servo_screw_height, servo_screw_hole_radius, servo_screw_hole_radius, center=true);
}

module arc_guide() {
    extra_wall = 2.5;
    difference() {
        // Offset the arc out the back, to keep the pivot aligned.
        linear_extrude(height = rotator_height, center = true)
            intersection() {
                translate([-extra_wall, -extra_wall, 0])
                    square(arc_radius*2, center = false);
                circle(arc_radius);
            }
   
        // Remove the bead drop hole.
        rotate([0, 0, bead_hole_angle])
            translate([arc_radius - bead_hole_to_edge, 0, 0])
                bead_hole_pattern();
            
        // Remove the servo screw holes
        union() {
            servo_screw_hole_pattern();
            translate([0 + servo_screw_spacing, 0, 0])
              servo_screw_hole_pattern();
        }
    }
}


module stable_arc() {
    extra_wall = 2.5;
    angle1 = 130;
    angle2 = 177;
    cut_width=arc_radius*2;

    translate([-(arc_radius - bead_hole_to_edge), 0, 0])
        rotate([0, 0, -bead_hole_angle])
    union() {
        difference() {
            // Offset the arc out the back, to keep the pivot aligned.
            cylinder(h = rotator_height, r = arc_radius, center = true);

            // Offset a smaller arc and remove it  to save material.
            cylinder(h = rotator_height+epsilon, r = arc_radius/2 + 2*extra_wall, center=true);

            // Remove the back of the arc.
            rotate([0, 0, angle1])
                translate([0, +cut_width/2, 0])
                    cube([cut_width, cut_width, rotator_height+epsilon], center=true);
            rotate([0, 0, angle2])
                translate([0, +cut_width/2, 0])
                    cube([cut_width, cut_width, rotator_height+epsilon], center=true);

            // Remove the bead drop hole.
            rotate([0, 0, bead_hole_angle])
                translate([arc_radius - bead_hole_to_edge, 0, 0])
                    bead_hole_pattern();
        }
    }
}

module rotating_arc_servo_mount() {
    extra_wall = 2.5;
    pivot_offset = 9.5;
    cutout_width = 24;
    cutout_depth = 13;
    servo_mount_hole_distance = 28;
    servo_mount_hole_dia = 3;  // 2mm + 1mm hole printing error.
    magic_alignment = 28;
    translate([servo_mount_hole_distance/2-pivot_offset, 0, 0])
        difference() {
            translate([0, -extra_wall, 0]) {
                hull() {
                    translate([arc_radius-magic_alignment, 0, 0])
                        cylinder(h=rotator_height, r=cutout_depth/2+extra_wall, center=true);
                    translate([-(pivot_offset+extra_wall), 0, 0])
                        cylinder(h=rotator_height, r=cutout_depth/2+extra_wall, center=true);
                }
            }
            cube([cutout_width, cutout_depth, rotator_height+epsilon], center=true);
            translate([-servo_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height+epsilon, r=servo_mount_hole_dia/2, center=true);
            translate([servo_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height+epsilon, r=servo_mount_hole_dia/2, center=true);
        }
}

module rotating_arc_level() {
    translate([-(arc_radius - bead_hole_to_edge), 0, 0])
        rotate([0, 0, -bead_hole_angle])
            arc_guide();
}

module rotating_arc_mount_level() {
    difference() {
        union() {
            cross_structure();
            translate([-(arc_radius - bead_hole_to_edge), 0, 0])
                rotate([0, 0, -bead_hole_angle])
                    rotating_arc_servo_mount();
        }
        cylinder(h=200, r=bead_hole_radius, center=true); 
    }
}

module stable_arc_level() {
    difference() {
        union() {
            difference() {
                rotate([0, 0, 90]) half_cross_structure();
                scale([1, 1, 1+epsilon]) hull() stable_arc();
            }
            stable_arc();
            half_cross_structure();
        }
        cylinder(h=200, r=bead_hole_radius, center=true); 
    }
}

module fall_through_cylinder() {
    translate([0, -drop_y-guide_pivot_offset, 0])
        cylinder(h=200, r=bead_hole_radius, center=true); 
}

module fall_through_straw() {
  estimate_height = 14;
  overshoot_height = estimate_height+40;
  translate([0, -drop_y-guide_pivot_offset, -overshoot_height/2])
      difference() {
          cylinder(h=overshoot_height, r=bead_hole_radius+wall_width, center=true);
          cylinder(h=overshoot_height+epsilon, r=bead_hole_radius, center=true);
      }
}

// This is a cylinder with a cube on top to help difference against the support.
module support_straw_cutout() {
  union() {
    rotate([90,0,0])
       cylinder(guide_length, guide_od/2, guide_od/2, center=true);
    translate([0, 0, support_straw_cutout_height/2])
      cube([guide_od, guide_length, support_straw_cutout_height], center=true);
  }
}

// A straw shape.
module closed_straw() {
    rotate([90,0,0])
        difference() {
            cylinder(guide_length, guide_od/2, guide_od/2, center=true);
            cylinder(guide_length-2*wall_width, guide_id/2, guide_id/2, center=true); 
        }
}

// A straw cut in half.
module half_straw() {
    difference() {
        closed_straw();
        translate([0,0,guide_length/2])
            cube([guide_length, guide_length+epsilon, guide_length], center=true);
    }
}

module stepper_shaft_hole_pattern() {
    intersection() {
        width = 3.5;  // 3mm measured.
        diameter = 7;  // 6mm measured.
        cube([width, diameter, stepper_motor_shaft_hole_height], center=true);
        cylinder(h = stepper_motor_shaft_hole_height, r = diameter/2, center=true, $fn=32);
    }
}

module slide_stepper_motor_bracket() {
    bracket_height = 30;  // Some gets chopped off by intersection.
    set_screw_radius = 1.5;
    set_screw_distance_from_end = 2;
        
    difference() {
        translate([0, -guide_pivot_offset, -bracket_height/2])
            cylinder(h = bracket_height, r = 4, center=true);
        // Take off the part that intersects the straw.
        rotate([slide_angle, 0, 0])
          translate([0, -guide_length/2+guide_pivot_offset, 0])
               support_straw_cutout();
        // Take out the stepper motor shaft.
        translate([0, 0, -(bracket_height-stepper_motor_shaft_hole_height/2+epsilon)])
            stepper_shaft_hole_pattern();
        // Add a hole for a set screw.
        translate([0, 0, -(bracket_height-set_screw_distance_from_end-set_screw_radius)])
            rotate([0, 90, 0])
                cylinder(h = 200, r=set_screw_radius, center=true);
    }
}

module slide_servo_bracket() {
  servo_screw_z = -support_height + servo_screw_height/2;
  difference() {
    // Start with a rectangle that intersects the straw.
    translate([0, -support_length/2, -support_height/2])
      cube([support_width, support_length, support_height], center=true);
    // Take off the part that intersects the straw.
    rotate([slide_angle, 0, 0])
      translate([0, -guide_length/2+guide_pivot_offset, 0])
           support_straw_cutout();       
    // Take out the screws.
    translate([0, -guide_pivot_offset, servo_screw_z])
      servo_screw_hole_pattern();
    translate([0, -guide_pivot_offset-servo_screw_spacing, servo_screw_z])
      servo_screw_hole_pattern();
  }
}

module slide() {
  difference() {
    // Start with a half_straw shape.
    rotate([slide_angle, 0, 0])
        translate([0, -guide_length/2+guide_pivot_offset, 0])
            half_straw();
    // Take off the top points, so it can be near the flat piece above.
    translate([0, 0, support_straw_cutout_height/2])
        cube([guide_od, guide_length, support_straw_cutout_height], center=true);
      
    // Remove a cylinder for things to fall through.
    fall_through_cylinder();
  }
}

module slide_fall_through() {
   difference() {
        fall_through_straw();
        rotate([slide_angle, 0, 0])
            translate([0, -guide_length/2+guide_pivot_offset, 0])
                support_straw_cutout();
    }
}

module slide_guide() {
  translate([0, guide_pivot_offset, 0])
      union() {
          slide();
          slide_fall_through();
          slide_stepper_motor_bracket();
      }
}

module slide_cover() {
    union() {
      slide_cover_length = 30;
      top_slit_width = 4;
      top_slit_length = slide_cover_length - wall_width*2;

      // Rotate it so it's properly oriented (but not on a 30deg tilt).
      rotate([0, 180, 0])
        difference() {
            translate([0, guide_length/2 - slide_cover_length, 0])
                half_straw();
            translate([0, guide_length/2, 0])
                cube([guide_length, guide_length, guide_length], center=true);
            translate([0, -top_slit_length/2, 0])
                cube([top_slit_width, top_slit_length, guide_od], center=true);
        }
    }
}


module half_cross_structure() {
    wall_width = 2.5;
    pos = tr_distance/2;
    center_cylinder_radius = 10;
    module threaded_rod_od() {
        cylinder(h = rotator_height, r=tr_radius+wall_width, center=true);
    }
    module threaded_rod_id() {
        cylinder(h = rotator_height+epsilon, r=tr_radius, center=true);
    }
    difference() {
        union() {
            hull() {
                translate([-pos, -pos, 0])
                    cylinder(h = rotator_height, r=wall_width, center=true);
                translate([pos, pos, 0])
                    cylinder(h = rotator_height, r=wall_width, center=true);
            }
            translate([-pos, -pos, 0]) threaded_rod_od();
            translate([+pos, +pos, 0]) threaded_rod_od();
            cylinder(h = rotator_height, r=center_cylinder_radius, center=true);
        }
        translate([-pos, -pos, 0]) threaded_rod_id();
        translate([+pos, +pos, 0]) threaded_rod_id();
    }
}

module cross_structure() {
    union() {
        half_cross_structure();
        rotate([0, 0, 90]) half_cross_structure();
    }
}

module fall_guide360() {
  drop_radius = drop_y;
  outer_radius = drop_radius + (bead_hole_radius + wall_width);
  inner_radius = drop_radius - (bead_hole_radius + wall_width);
  middle_radius = (outer_radius + inner_radius) / 2;

  module ring() {
      difference() {
          cylinder(h=rotator_height, r=outer_radius, center=true);
          cylinder(h=rotator_height+epsilon, r=inner_radius, center=true);
      }
  }
  difference() {
      union() {
        ring();
        cross_structure();
      }

      // Take out the holes.
      for ( d = [0 : (360/64 * 2) : 359] ){  
          rotate([0, 0, d])
            rotate([0, 0, 360/64])  // Don't put holes on axes.
              translate([0, guide_pivot_offset, 0])
                  fall_through_cylinder();
      }
  }
}

module fall_guide90() {
    intersection() {
        fall_guide360();
        translate([100, 100, 0])
            cube([200, 200, rotator_height], center=true);
    }
}


module sensor_mount() {
    extra_wall = 2.5;
    pivot_offset = 9;
    sensor_see_hole = 12;
    sensor_sit_hole = 21;
    sensor_screw_hole_radius = 1.5;  // FIXME
    sensor_block_width = sensor_sit_hole + 2*extra_wall;
    sensor_block_depth = sensor_sit_hole + 4*extra_wall;
    sensor_screw_hole_x_offset = 7;  // Measured 14mm/2.
    sensor_screw_hole_y_offset = 8;  // Measured 20mm/2-2mm -> 8.
    union() {
        difference() {
            cube([sensor_block_width, sensor_block_depth, rotator_height], center=true);
            translate([0, 0, rotator_height/4+epsilon])
                cube([sensor_sit_hole, sensor_sit_hole, rotator_height/2], center=true);
            cube([sensor_see_hole, sensor_see_hole, rotator_height+epsilon], center=true);
            translate([sensor_screw_hole_x_offset, sensor_screw_hole_y_offset, 0])
                cylinder(h = 200, r = sensor_screw_hole_radius, center=true);
            translate([sensor_screw_hole_x_offset, -sensor_screw_hole_y_offset, 0])
                cylinder(h = 200, r = sensor_screw_hole_radius, center=true);
        }

    }
}

module sensor_mount_level() {
  module oriented_sensor_mount() {
    pivot_on_arc_axis(sensor_angle)
          sensor_mount();
  }
  union() {
      difference() {
          cross_structure();
          scale([1, 1, 1+epsilon]) hull() oriented_sensor_mount();
      }
      oriented_sensor_mount();
  }
}

// Debugging visual aids visible only in 'preview' mode.
module threaded_rods() {
    pos = tr_distance/2;
    module threaded_rod_id() {
        cylinder(h = 200, r=tr_radius, center=true);
    }
    union() {
        translate([-pos, -pos, 0]) threaded_rod_id();
        translate([-pos, +pos, 0]) threaded_rod_id();
        translate([+pos, -pos, 0]) threaded_rod_id();
        translate([+pos, +pos, 0]) threaded_rod_id();
    }
}

module bead_hole_axis() {
  scale([1, 1, 200/rotator_height])
    bead_hole_pattern();
}

module arc_pivot_axis() {
    x_offset = arc_radius - bead_hole_to_edge;
    translate([-x_offset, 0, 0])
        cylinder(h = 200, r = servo_screw_hole_radius, center=true);
}

module debug_aids() {
    %union() {
        threaded_rods();
        bead_hole_axis();
        pivot_on_arc_axis(sensor_angle) {
            bead_hole_axis();
            translate([0, 0, -10]) scale([0.99, 0.99, 0.99])
                rotating_arc_level();
        }
        pivot_on_arc_axis(entry_angle) {
            bead_hole_axis();
            translate([0, 0, -10]) scale([0.98, 0.98, 0.98])
                rotating_arc_level();
        }
        arc_pivot_axis();
        
    }
}

module stack() {
    translate([0, 0, 20])
        slide_cover();

    translate([0, 0, 10])
        sensor_mount_level();

    translate([0, 0, 0])
        rotating_arc_mount_level();

    translate([0, 0, -10])
        rotating_arc_level();

    translate([0, 0, -20])
        stable_arc_level();

    translate([0, 0, -30])
        slide_guide();

    translate([0, 0, -90]) {
        fall_guide360();
        %stepper_motor();
    }
}


debug_aids();
// stack();
// fall_guide90();
// slide_guide();
// sensor_mount();
// sensor_mount_level();
// stable_arc();
 stable_arc_level();

// rotating_arc_mount_level();
//    rotate([0, 0, +bead_hole_angle])
//        rotating_arc_level();


module stepper_motor() {
    union() {
        h1 = 20;
        h2 = 4;
        stepper_motor_shaft_x_offset = 10;  // Offset from center: measured 6mm from edge.
        #translate([0, 0, h1+h2+stepper_motor_shaft_hole_height/2])
            stepper_shaft_hole_pattern();
        translate([0, 0, h1+h2/2])
            cylinder(h = h2, r = 5, center=true);
        translate([stepper_motor_shaft_x_offset, 0, +h1/2])
            cylinder(h = h1, r = 16, center=true);
    }
}