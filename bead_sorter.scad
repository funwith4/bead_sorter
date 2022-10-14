echo(version=version());

// https://learn.adafruit.com/adafruit-color-sensors/downloads

m3_tight_radius = 1.8;  // Experience with stepper motor mount.
m4_tight_radius = 2.3;  // Guess, based on m3 + 1mm.
m1p7_tight_radius = 1;  // Experience with servo horn mount.
m2p3_tight_radius = 1.4;
sae_1_4_tight_radius = 3.5;   // Experience with threaded rod.
sae_1_4_loose_radius = 3.75;  // Experience with threaded rod.


rotator_height = 7;
bead_hole_radius = 4.1;
bead_hole_distance_from_edge = bead_hole_radius+3;
bead_hole_arc_radius = 40;
bead_hole_angle = 15;
arc_radius = bead_hole_arc_radius+bead_hole_distance_from_edge;  // 50 hits the tcs34725 screws.
arc_angle = 130;
arc_inside_radius = bead_hole_arc_radius - bead_hole_distance_from_edge;
sensor_angle = 40;
entry_angle = 80;
servo_horn_screw_hole_radius = m1p7_tight_radius;
servo_horn_screw1_x_offset = 6.5;  // FIXME?
servo_horn_screw2_x_offset = 12.5;
stepper_motor_shaft_hole_height = 100;
stepper_motor_shaft_min_width = 3.5;  // 3mm measured, squared sides.
stepper_motor_shaft_max_radius = 3.1;  // 6mm diameter measured, rounded sides.
stepper_motor_height = 18;
stepper_motor_radius = 29/2;  // 28.2mm measured diameter.
stepper_motor_mount_hole_distance = 35;  // Distance between mount holes on center.
stepper_motor_shaft_y_offset = stepper_motor_radius - 6;  // Offset from center: measured 6mm from edge.

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
tr_radius = sae_1_4_loose_radius;
tr_distance = 116;
epsilon = 0.02;  // Enough to avoid z-fighting.

// Previously, before bringing it in to fit on the bed.
// drop_y=guide_length*0.75-guide_pivot_offset;
// guide_length=100;


module pivot_on_arc_axis(d) {
    x_offset = bead_hole_arc_radius;
    translate([-x_offset, 0, 0])
        rotate([0, 0, d])
            translate([+x_offset, 0, 0])
                children();
}

module bead_hole_pattern() {
  cylinder(h=rotator_height+epsilon, r=bead_hole_radius, center=true);
}

module bead_funnel(h) {
  bottom_r_od = bead_hole_radius+wall_width;
  top_increase = h/5;
  difference() {
      cylinder(h=h, r1=bottom_r_od, r2=bottom_r_od+top_increase, center=true);
      cylinder(h=h+epsilon, r1=bead_hole_radius, r2=bead_hole_radius+top_increase, center=true);
  }
}

module servo_horn_screw_hole_pattern() {
  cylinder(h=rotator_height+epsilon, r=servo_horn_screw_hole_radius, center=true);
}

module rotating_arc() {
    arc_angle = 130;
    horn_angle = (arc_angle-90)/2;
    horn_mount_radius = wall_width;
    horn_mount_length = arc_radius - horn_mount_radius;
    module support() {
        hull() {
            cylinder(h=rotator_height, r=horn_mount_radius, center=true);
            translate([horn_mount_length, 0, 0])
                cylinder(h=rotator_height, r=horn_mount_radius, center=true);
        }                
    }
    difference() {
        union() {
            difference() {
                pie_wedge(h=rotator_height, r=arc_radius, d=arc_angle);
                // Remove smaller arc to save material.
                cylinder(h = rotator_height+epsilon, r = arc_inside_radius, center=true);
            }
            rotate([0, 0, horn_angle]) support();
            rotate([0, 0, 90+horn_angle]) support();
        }
    
        // Remove the bead drop hole.
        rotate([0, 0, bead_hole_angle])
            translate([bead_hole_arc_radius, 0, 0])
                bead_hole_pattern();
            
        // Remove the servo screw holes
        rotate([0, 0, horn_angle]) union() {
            servo_horn_screw_hole_pattern();
            translate([servo_horn_screw1_x_offset, 0, 0])
              servo_horn_screw_hole_pattern();
            translate([servo_horn_screw2_x_offset, 0, 0])
              servo_horn_screw_hole_pattern();
        }
    }
}

module pie_wedge(h, r, d) {
  difference() {
      cylinder(h = h, r = r, center = true);

      // Remove the back of the arc.
      rotate([0, 0, d])
        translate([0, +r, 0])
            cube([r*2, r*2, h+epsilon], center=true);
      translate([0, -r, 0])
        cube([r*2, r*2, h+epsilon], center=true);
  }
}

module stable_arc() {    
    translate([-bead_hole_arc_radius, 0, 0])
    rotate([0, 0, -bead_hole_angle])
    difference() {
        pie_wedge(h=rotator_height, r=arc_radius, d=130);
        
        // Remove smaller arc to save material and allow horn to pivot.
        cylinder(h = rotator_height+epsilon, r = arc_inside_radius, center=true);

        // Remove the bead drop hole.
        rotate([0, 0, bead_hole_angle])
            translate([bead_hole_arc_radius, 0, 0])
                bead_hole_pattern();
    }
}

module rotating_arc_servo_mount() {
    extra_wall = 2.5;
    pivot_offset = 9.5;
    cutout_width = 24;
    cutout_depth = 13;
    servo_stepper_motor_mount_hole_distance = 28;
    servo_mount_hole_dia = 3;  // 2mm + 1mm hole printing error.
    magic_alignment = 28;
    translate([servo_stepper_motor_mount_hole_distance/2-pivot_offset, 0, 0])
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
            translate([-servo_stepper_motor_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height+epsilon, r=servo_mount_hole_dia/2, center=true);
            translate([servo_stepper_motor_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height+epsilon, r=servo_mount_hole_dia/2, center=true);
        }
}

module rotating_arc_level() {
    translate([-bead_hole_arc_radius, 0, 0])
        rotate([0, 0, -bead_hole_angle])
            rotating_arc();
}

module rotating_arc_mount_level() {
    difference() {
        union() {
            cross_structure();
            translate([-bead_hole_arc_radius, 0, 0])
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
    cylinder(h=200, r=bead_hole_radius, center=true); 
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

module stepper_shaft_hole_pattern() {
    intersection() {
        cube([stepper_motor_shaft_min_width, 2*stepper_motor_shaft_max_radius, stepper_motor_shaft_hole_height], center=true);
        cylinder(h = stepper_motor_shaft_hole_height, r = stepper_motor_shaft_max_radius, center=true, $fn=32);
    }
}

module slide_stepper_motor_bracket() {
    bracket_height = 32;  // Some gets chopped off by intersection.
    bracket_radius = stepper_motor_shaft_max_radius + wall_width;
    set_screw_radius = 1.5;
    set_screw_distance_from_end = 2;
        
    difference() {
        translate([0, 0, -bracket_height/2])
            cylinder(h = bracket_height, r = bracket_radius, center=true);
        // Take out the stepper motor shaft.
        stepper_shaft_hole_pattern();
        // Add a hole for a set screw.
        translate([0, 0, -(bracket_height-set_screw_distance_from_end-set_screw_radius)])
            rotate([0, 90, 0])
                cylinder(h = 200, r=set_screw_radius, center=true);
    }
}

// straw_y_offset = -guide_length/2+2+guide_pivot_offset-wall_width;

straw_y_offset = -(drop_y/2+guide_pivot_offset);

// The bulk of the slide. This is expected to be cut into top and botton, at
// which point the masks for bead fall throughs must be applied. The masks cannot
// be applied to the full slide because holes don't extend through both the
// top and bottom.
module slide() {
    slot_width = 3;
    slot_end_buffer = 15;
    slot_mask_height = 15;
    screw_mount_height = 6;
    screw_mount_radius = m1p7_tight_radius + wall_width;
    screw_mount_y_offset = guide_length/2+wall_width;
    depth = guide_length-slot_end_buffer;
    module horizontal_straw() {
        difference() {
            union() {
              rotate([90,0,0])
                  cylinder(h=guide_length, r=guide_od/2, center=true);
              hull() {
                  translate([0, -screw_mount_y_offset, 0])
                    cylinder(h=screw_mount_height, r=screw_mount_radius, center=true);
                  translate([0, +screw_mount_y_offset, 0])
                    cylinder(h=screw_mount_height, r=screw_mount_radius, center=true);
              }
           }
           translate([0, -screw_mount_y_offset, 0])
               cylinder(h=screw_mount_height+epsilon, r=m1p7_tight_radius, center=true);
           translate([0, +screw_mount_y_offset, 0])
               cylinder(h=screw_mount_height+epsilon, r=m1p7_tight_radius, center=true);
        }
    }
    module slide_funnel() {
        translate([0, 0, 8]) bead_funnel(20);
    }
    module slot() {
        rotate([slide_angle, 0, 0])
            translate([0, -depth/2, slot_mask_height/2])
                minkowski() {    
                    cube([epsilon, depth, slot_mask_height],center=true);
                    sphere(slot_width/2, $fn=24);
                }
    }

    difference() {
        union() {
            difference() {
                rotate([slide_angle, 0, 0])
                    translate([0, straw_y_offset, 0])
                      horizontal_straw();
                hull() slide_funnel();
            }
            slide_funnel();
        }
        slot();
    }
}

// A mask used to separate the top from the bottom and cut out the inside
// of the straw.
module slide_mask() {
    union() {
        translate([0, 0, -100]) cube([200, 200, 200], center=true);
        translate([0, straw_y_offset, 0]) rotate([90,0,0]) 
            cylinder(guide_length-2*wall_width, guide_id/2, guide_id/2, center=true);      
    }
}

module slide_top() {
    difference() {
        slide();
        rotate([slide_angle, 0, 0]) slide_mask();   
    }
}

//!slide_top();

module slide_bottom() {
    difference() {
        union() {
            slide();
            slide_stepper_motor_bracket();
            slide_out_cylinder();
        }
        rotate([slide_angle, 0, 0]) rotate([0, 180, 0]) slide_mask();
        translate([0, -drop_y, 0]) fall_through_cylinder();
    }
}

// !slide_bottom();
module slide_out_cylinder() {
  estimate_height = 14;
  overshoot_height = estimate_height+40;
  translate([0, -drop_y, -overshoot_height/2])
      cylinder(h=overshoot_height, r=bead_hole_radius+wall_width, center=true);
}

module threaded_rod_od(h) {
    cylinder(h = h, r=tr_radius+wall_width, center=true);
}

module threaded_rod_id() {
    cylinder(h = 200, r=tr_radius, center=true);
}

module stabilizer_old() {
    nut_inset = [11.5, 12.8, 8];  // Measured [11mm, 12.3mm, 5.5mm].
    nut_outset = [wall_width, wall_width, wall_width] + nut_inset;
    stabilizer_height = 30;
    
    module nut_holder() {
        difference() {
            hull() {
                translate([0, 0, +stabilizer_height/2+wall_width]) cube(nut_outset, center=true);
                cube([1,1,1], center=true);
            }
            translate([0, 0, stabilizer_height/2+2*wall_width+epsilon]) cube(nut_inset, center=true);
        }
    }
        
    difference() {
        union() {
            nut_holder();
            rotate([0, 180, 0]) nut_holder();
            threaded_rod_od(stabilizer_height);
        }
        threaded_rod_id();
    }
}

module stabilizer() {
    nut_inset = [11.5, 12.8, 8];  // Measured [11mm, 12.3mm, 5.5mm].
    nut_outset = [wall_width, wall_width, wall_width] + nut_inset;
    stabilizer_height = 30;
    
    module nut_holder() {
        difference() {
            hull() {
                translate([0, 0, +stabilizer_height/2+wall_width]) cube(nut_outset, center=true);
                cube([1,1,1], center=true);
            }
            translate([0, 0, stabilizer_height/2+2*wall_width+epsilon]) cube(nut_inset, center=true);
        }
    }
        
    difference() {
        union() {
            nut_holder();
            // rotate([0, 180, 0]) nut_holder();
            threaded_rod_od(stabilizer_height);
        }
        threaded_rod_id();
    }
}


module half_cross() {
    wall_width = 2.5;
    pos = tr_distance/2;
    center_cylinder_radius = 10;

    difference() {
        union() {
            hull() {
                translate([-pos, -pos, 0])
                    cylinder(h = rotator_height, r=wall_width, center=true);
                translate([pos, pos, 0])
                    cylinder(h = rotator_height, r=wall_width, center=true);
            }
            translate([-pos, -pos, 0]) children();
            translate([+pos, +pos, 0]) children();
            cylinder(h = rotator_height, r=center_cylinder_radius, center=true);
        }
        translate([-pos, -pos, 0]) threaded_rod_id();
        translate([+pos, +pos, 0]) threaded_rod_id();
    }
}

module full_cross() {
    union() {
        half_cross() children(0);
        rotate([0, 0, 90]) half_cross() children(0);
    }
}

module cross_stabilizer_structure() {
  full_cross() rotate([0, 0, 45]) translate([0, 0, 5]) stabilizer();
}

module threaded_rod_slider(h) {
    difference() {
        threaded_rod_od(h);
        threaded_rod_id();
    }
}

module cross_structure() {
    full_cross() threaded_rod_slider(rotator_height);
}

module half_cross_structure() {
    half_cross() threaded_rod_slider(rotator_height);
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
        translate([0, 0, rotator_height/2]) union() {
            %stepper_motor(); 
            stepper_motor_mount();
        }
      }

      // Take out the holes.
      for ( d = [0 : (360/64 * 2) : 359] ){  
          rotate([0, 0, d])
            rotate([0, 0, 360/64])  // Don't put holes on axes.
                translate([0, -drop_y, 0])
                  fall_through_cylinder();
      }
  }
}

module collector() {
    collector_length = 100;
    difference() {
        cylinder(h=collector_length, r=guide_od/2, center=true);
        translate([0, 0, wall_width])
            cylinder(h=collector_length+epsilon, r=guide_id/2, center=true);
        translate([0, -100, 0])
            cube([200, 200, collector_length+epsilon], center=true);
    }
}

module collector_array() {
      difference() {
          union() {
              for ( d = [0 : (360/64 * 2) : 359] ){  
                  rotate([0, 0, d])
                    rotate([0, 0, 360/64])  // Don't put holes on axes.
                        translate([0, -drop_y, 0])
                          rotate([-30, 0, 0]) collector();
              }
          }
          translate([0, 0, 100-rotator_height/2])
            cube([200, 200, 200], center=true);
      }
}

//collector_array();
//fall_guide360();

module sensor_mount() {
    extra_wall = 2.5;
    sensor_sit_hole = 21;
    sensor_sit_hole_height = 4;
    sensor_sit_hole_lift = 2;  // Sensor floor sits 2mm above level floor.
    sensor_block_width = sensor_sit_hole + 2*extra_wall;
    sensor_header_channel_width = 5;
    sensor_screw_hole_radius = m2p3_tight_radius;
    sensor_screw_hole_x_offset = 8;  // Measured 14mm/2, moved after trying it.
    sensor_screw_hole_y_offset = 8;  // Measured 20mm/2-2mm -> 8.
    difference() {
        cube([sensor_block_width, sensor_block_width, rotator_height], center=true);
        // Take out the sit hole (sensor is mounted from the bottom).
        translate([0, 0, -sensor_sit_hole_height/2])
            cube([sensor_sit_hole, sensor_sit_hole, sensor_sit_hole_height+epsilon], center=true);
        // Take out the sensor mounting screw holes.
        translate([sensor_screw_hole_x_offset, sensor_screw_hole_y_offset, 0])
            cylinder(h = 200, r = sensor_screw_hole_radius, center=true);
        translate([sensor_screw_hole_x_offset, -sensor_screw_hole_y_offset, 0])
            cylinder(h = 200, r = sensor_screw_hole_radius, center=true);
        // A channel for the headers to poke through.
        translate([-(sensor_sit_hole/2-sensor_header_channel_width/2), 0, 0])
            cube([sensor_header_channel_width, sensor_sit_hole, rotator_height+epsilon], center=true);
    }
}

module sensor_mount_level() {
  module oriented_sensor_mount() {
    pivot_on_arc_axis(sensor_angle)
          sensor_mount();
  }
  union() {
      difference() {
          stable_arc_level();
          scale([1, 1, 1+epsilon]) hull() oriented_sensor_mount();
          pivot_on_arc_axis(entry_angle) bead_hole_axis();
      }
      oriented_sensor_mount();
  }
}

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
    x_offset = bead_hole_arc_radius;
    translate([-x_offset, 0, 0])
        cylinder(h = 200, r = servo_horn_screw_hole_radius, center=true);
}

module stepper_motor() {
    union() {
        h1 = stepper_motor_height + 1;
        h2 = 3;
        h3 = 2;
        translate([0, 0, +h1+h2+h3/2])
            #cylinder(h = h1, r = 2, center=true);
        translate([0, 0, h1+h2/2])
            cylinder(h = h2, r = 5, center=true);
        translate([0, stepper_motor_shaft_y_offset, +h1/2])
            cylinder(h = h1, r = stepper_motor_radius, center=true);
        
    }
}

module stepper_motor_mount() {
  stepper_motor_bracket_height = stepper_motor_height + wall_width;
  pedestal_radius = wall_width + m4_tight_radius;
  distance_from_center=stepper_motor_mount_hole_distance/2;
  module pedestal(h) {
      hull() {
          translate([0, distance_from_center, 0])
              cylinder(h=h, r=pedestal_radius, center=true);
          cylinder(h=h, r=pedestal_radius, center=true);
      }
  }

  translate([0, stepper_motor_shaft_y_offset, stepper_motor_bracket_height/2-wall_width]) union() {
  difference() {
      union() {
          rotate([0, 0, 90]) pedestal(stepper_motor_bracket_height);
          rotate([0, 0, 180]) pedestal(stepper_motor_bracket_height);
          rotate([0, 0, 270]) pedestal(stepper_motor_bracket_height);
      }
      cylinder(h = stepper_motor_bracket_height+epsilon, r=stepper_motor_radius, center=true);
      translate([stepper_motor_mount_hole_distance/2, 0, 0])
          cylinder(h=200, r=m4_tight_radius, center=true);
      translate([-stepper_motor_mount_hole_distance/2, 0, 0])
          cylinder(h=200, r=m4_tight_radius, center=true);

  }
  translate([0, 0, -stepper_motor_bracket_height/2+wall_width/2])
    difference() {
      hull() {
          pedestal(wall_width);
          rotate([0, 0, 90]) pedestal(wall_width);
          rotate([0, 0, 180]) pedestal(wall_width);
          rotate([0, 0, 270]) pedestal(wall_width);
      }
      // Give it a little channel for the wires to be tucked in to.
      hull() {
          translate([1, 18, 0]) cylinder(h = 10, r=1.5, center=true);
          translate([-10, 18, 0]) cylinder(h = 10, r=1.5, center=true);
      }
    }
  }
}

// Debugging visual aids visible only in 'preview' mode.
module debug_aids() {
    z_value = 0;
    %union() {
        threaded_rods();
        bead_hole_axis();
        pivot_on_arc_axis(sensor_angle) {
            bead_hole_axis();
            translate([0, 0, z_value]) scale([0.99, 0.99, 0.99])
                rotating_arc_level();
        }
        pivot_on_arc_axis(entry_angle) {
            bead_hole_axis();
            translate([0, 0, z_value]) scale([0.98, 0.98, 0.98])
                rotating_arc_level();
        }
        arc_pivot_axis();
    }
}

/*

module fall_guide90() {
    intersection() {
        fall_guide360();
        translate([100, 100, 0])
            cube([200, 200, rotator_height], center=true);
    }
}

module fall_guide360_inside_template() {
    rotate([0, 0, 45]) cube([80, 80, 100], center=true);
}

module fall_guide360_inside() {
  intersection() {
      fall_guide360();
      fall_guide360_inside_template();
  }
}

module fall_guide360_outside(i) {
    intersection() {
        difference() {
              fall_guide360();
              fall_guide360_inside_template();
        }
        rotate([0, 0, 90*i])
          translate([tr_distance/2, tr_distance/2, 0])
            cube([tr_distance, tr_distance, 100], center=true);
    }
}

    // Probably not going to work due to slushiness on the abutting edges.
    fall_guide360_inside();
    fall_guide360_outside(0);
    fall_guide360_outside(1);
    fall_guide360_outside(2);
    fall_guide360_outside(3);
*/


module stack() {
    translate([0, 0, 50])
        sensor_mount_level();

    translate([0, 0, 40])
        rotating_arc_level();

    translate([0, 0, 30])
        stable_arc_level();
    
    translate([0, 0, 10])
        rotating_arc_mount_level();

    translate([0, 0, -25])
        slide_top();

    translate([0, 0, -30]) {
        slide_bottom();
        for ( d = [90 : 90 : 359] ){  
            rotate([0, 0, d])
                %slide_bottom();
        }
    }
    
    translate([0, 0, -90]) {
        union() {
            fall_guide360();
        }
    }
    
    translate([0, 0, -110]) {
        rotate([180, 0, 0])
        cross_stabilizer_structure();
    }
}

// rotating_arc();

/*
difference() {
    stabilizer();
    translate([0, 0, 15]) cube([30, 30, 30], center=true);
}
*/
/*
intersection() {
  stepper_motor_mount();
  translate([20, 10, 15]) cube([20, 20, 20], center=true);
}
*/
// cross_stabilizer_structure();
// stabilizer();
// debug_aids();
//stack();
//stable_arc();
//slide_top();

// FIXME: Add a servo horn hole.

// fall_guide90();
/* // shortened stepper motor shaft mount
difference() {
    slide_stepper_motor_bracket();
    cube([20,20,47], center=true);
}
*/
// threaded_rod_slider(rotator_height+1);
//threaded_rod_slider(10);

//sensor_mount();
// sensor_mount_level();
// stable_arc();
// stable_arc_level();
// stepper_motor();
// stepper_motor_mount();
//fall_guide360();
// rotating_arc_mount_level();
//    rotate([0, 0, +bead_hole_angle])
//        rotating_arc_level();

module collector_guide(inner_radius, outer_radius) {
    height = 5;
    grip_width=2;
    floor_height = 1;
    module grip_mask() {
        translate([0, -outer_radius/2, 1])
            cube([grip_width, outer_radius, height-1], center=true);
    }
    difference() {
        cylinder(h=height, r=outer_radius, center=true);
        cylinder(h=height+epsilon, r=inner_radius, center=true);
        for ( d = [0 : (360/64 * 2) : 359] ){  
            rotate([0, 0, d]) grip_mask();
        }
    }
}

/*intersection() {
    union() {
        %fall_guide360();
       collector_guide(35, 40);
       //collector_guide(65, 70);
    }
    pie_wedge(5, 75, 35);
}
*/
       collector_guide(10, 15);
