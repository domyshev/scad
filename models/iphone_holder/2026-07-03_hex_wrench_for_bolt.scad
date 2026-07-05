// Simple printable box-end wrench for the iPhone holder bolt.
//
// The bolt head in 2026-07-03_iphone_15_pro_max_hollow_box.scad is:
//   cylinder(d = 16, h = 5, $fn = 6)
//
// A 16 mm hex by circumscribed diameter has about 13.86 mm across flats.
// This wrench adds clearance so the printed ring head can slide over the head.

$fn = 64;

bolt_head_corner_d = 16;
bolt_head_across_flats = bolt_head_corner_d * cos(30);

wrench_clearance = 0.6;
wrench_opening_across_flats = bolt_head_across_flats + wrench_clearance;
wrench_opening_corner_d = wrench_opening_across_flats / cos(30);

wrench_thickness = 5;
wrench_head_outer_d = 34;
wrench_handle_length = 92;
wrench_handle_width = 14;
wrench_handle_end_d = 20;
wrench_hanger_hole_d = 7;

module wrench_outline_2d() {
    union() {
        circle(d = wrench_head_outer_d);

        hull() {
            translate([-wrench_handle_length, 0])
                circle(d = wrench_handle_width);

            translate([-8, 0])
                circle(d = wrench_handle_width);
        }

        translate([-wrench_handle_length, 0])
            circle(d = wrench_handle_end_d);
    }
}

module wrench_cutouts_2d() {
    union() {
        rotate(30)
            circle(d = wrench_opening_corner_d, $fn = 6);

        translate([-wrench_handle_length, 0])
            circle(d = wrench_hanger_hole_d);
    }
}

linear_extrude(height = wrench_thickness)
    difference() {
        wrench_outline_2d();
        wrench_cutouts_2d();
    }
