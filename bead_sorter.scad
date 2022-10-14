echo(version=version());

arc_radius = 50;
rotator_height = 7;
bead_hole_radius = 4;
bead_hole_to_edge = 10;
bead_hole_angle = 15;
sensor_angle = 45-bead_hole_angle;
structural_screw_hole_radius = 2;
structural_screw_hole_to_edge = 10;
structural_screw_spacing = 20;
servo_screw_hole_radius = 1;
servo_screw_hole_to_edge = 10;
servo_screw_spacing = 12.5;
servo_screw_height = 10;
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
tr_radius = 3.5;  // 1/4" (7m) diameter threaded rod.

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
    extra_wall = 5;
    difference() {
        // Offset the arc out the back, to keep the pivot aligned.
        linear_extrude(height = rotator_height, center = true)
            intersection() {
                translate([-extra_wall/2, -extra_wall/2, 0])
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
    extra_wall = 5;
    translate([-(arc_radius - bead_hole_to_edge), 0, 0])
        rotate([0, 0, -bead_hole_angle])
    difference() {
        // Offset the arc out the back, to keep the pivot aligned.
        linear_extrude(height = rotator_height, center = true)
            intersection() {
                translate([-extra_wall/2, -extra_wall/2, 0])
                    square(arc_radius*2, center = false);
                circle(arc_radius);
            }

        // Offset a smaller arc and remove it  to save material.
        linear_extrude(height = rotator_height, center = true)
            intersection() {
              translate([-extra_wall/2, -extra_wall/2, 0])
                  square(arc_radius, center = false);
              circle(arc_radius/2 + sqrt(2)*extra_wall);
            }
    
        // Remove the bead drop hole.
        rotate([0, 0, bead_hole_angle])
            translate([arc_radius - bead_hole_to_edge, 0, 0])
                bead_hole_pattern();
    }
}

module rotating_arc_servo_mount() {
    extra_wall = 2.5;
    pivot_offset = 9;
    cutout_width = 23;
    cutout_depth = 13;
    servo_mount_hole_distance = 28;
    servo_mount_hole_dia = 3;  // 2mm + 1mm hole printing error.
    magic_alignment = 27;
    translate([servo_mount_hole_distance/2-pivot_offset, 0, 0])
        difference() {
            hull() {
                translate([arc_radius-magic_alignment, 0, 0])
                    cylinder(h=rotator_height, r=cutout_depth/2+extra_wall, center=true);
                translate([-(pivot_offset+extra_wall), 0, 0])
                    cylinder(h=rotator_height, r=cutout_depth/2+extra_wall, center=true);
            }
            cube([cutout_width, cutout_depth, rotator_height], center=true);
            translate([-servo_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height*2, r=servo_mount_hole_dia/2, center=true);
            translate([servo_mount_hole_distance/2, 0, 0])
                cylinder(h=rotator_height*2, r=servo_mount_hole_dia/2, center=true);
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
            cross_structure();
            stable_arc();
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
          cylinder(h=overshoot_height, r=bead_hole_radius, center=true);
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
            cylinder(guide_length-5, guide_id/2, guide_id/2, center=true); 
        }
}

// A straw cut in half.
module half_straw() {
    difference() {
        closed_straw();
        translate([0,0,guide_length/2])
            cube([guide_length, guide_length, guide_length], center=true);
    }
}

module slide_bracket() {
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
          slide_bracket();
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


module semi_circle() {
    drop_radius = drop_y;
    outer_radius = drop_radius + (bead_hole_radius + wall_width);
    inner_radius = drop_radius - (bead_hole_radius + wall_width);
    translate([0,0,-55])
      union() {
        difference() {
            cylinder(h=rotator_height, r=outer_radius);
            translate([0, outer_radius, rotator_height/2])
                cube([outer_radius*2, outer_radius*2, rotator_height], center=true);
            // Don't waste material on a full semi-circle.
            cylinder(h=rotator_height, r=inner_radius);  
        }
        // Add some horizontal supports
        translate([-outer_radius, 0, 0])
            cube([outer_radius*2, 10, rotator_height]);
        rotate([0, 0, 180])
            translate([0, outer_radius/2, rotator_height/2])
               cube([10, outer_radius, rotator_height], center=true);
      }
  }


// Fall guide.
module fall_guide() {
  translate([0, 0, -20]) {
    difference() {
      semi_circle();

      for ( d = [-90 : 15 : 90] ){  
          rotate([0, 0, d])
              translate([0, guide_pivot_offset, 0])
                  fall_through_cylinder();
      }
    }
  }
}

module square_structure() {
    difference() {
        cube([140, 140, rotator_height], center=true);
        cube([120, 120, rotator_height], center=true);
        for ( x = [-1 : 2 : 1] ){
          for ( y = [-1 : 2 : 1] ){    
              translate([x*128/2, y*128/2, 0])
                  cylinder(h = rotator_height, r=tr_radius, center=true);
          }
        }
    }
}


module half_cross_structure() {
    wall_width = 5;
    pos = 128/2;
    difference() {
        hull() {
            translate([-pos, -pos, 0])
                cylinder(h = rotator_height, r=tr_radius+wall_width/2, center=true);
            translate([pos, pos, 0])
                cylinder(h = rotator_height, r=tr_radius+wall_width/2, center=true);
        }
        translate([-pos, -pos, 0])
              cylinder(h = rotator_height, r=tr_radius, center=true);
        translate([pos, pos, 0])
              cylinder(h = rotator_height, r=tr_radius, center=true);
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
          cylinder(h=rotator_height, r=inner_radius, center=true);
      }
  }
  difference() {
      union() {
        ring();
        // Center pivot.
        cylinder(h=rotator_height, r=10, center=true);
        
        // Supports out from the middle.
        for ( d = [0 : 45 : 136] ){  
          rotate([0, 0, d])
              cube([middle_radius*2, 5, rotator_height], center=true);
        }
 
        square_structure();
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

module stack() {
    translate([0, 0, 20])
        slide_cover();

    translate([0, 0, 0])
        rotating_arc_mount_level();

    translate([0, 0, -10])
        rotating_arc_level();

    translate([0, 0, -20])
        stable_arc_level();

    translate([0, 0, -30])
        slide_guide();

    translate([0, 0, -90])
        fall_guide360();
}

// fall_guide90();
// stack();
// slide_guide();

// rotating_arc_mount_level();
    translate([0, 0, -20])
        rotating_arc_level();


// Guide hole.
pivot_on_arc_axis(sensor_angle)
    scale([1, 1, 5])
        bead_hole_pattern();


module sensor_mount() {
    extra_wall = 2.5;
    pivot_offset = 9;
    sensor_see_hole = 12;  // FIXME
    sensor_sit_hole = 16;  // FIXME
    sensor_block_width = sensor_sit_hole + 2*extra_wall;
    sensor_block_depth = 2*sensor_block_width;

    union() {
        cross_structure();
        pivot_on_arc_axis(sensor_angle)
        translate([0, 0, 10])  // REMOVE ME
        difference() {
            cube([sensor_block_width, sensor_block_depth, rotator_height], center=true);
            translate([0, 0, +rotator_height/4])
                cube([sensor_sit_hole, sensor_sit_hole, rotator_height/2], center=true);
            cube([sensor_see_hole, sensor_see_hole, rotator_height], center=true);
        }

    }
}

sensor_mount();