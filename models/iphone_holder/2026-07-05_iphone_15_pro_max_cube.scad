// Cuboid iPhone 15 Pro Max holder base.
//
// This model is a new iteration after printing the 2026-07-03 hollow box:
// - external base is shorter and wider for lower center of gravity;
// - top lid is 12 mm thick;
// - bracket is an independent detachable part;
// - bracket mounting holes in the lid are blind, 8.5 mm deep;
// - two M20 threaded through holes in the lid can be used as fill ports.

$fn = 32;
preview_fast = $preview;

use <../../lib/core/threads/threads.scad>

// The Y size stays 80 mm. Width is perpendicular to the axis between the
// bracket mounting holes, so X grows by 30 mm on each side. Z is 30 mm lower.
base_x = 140;
base_y = 80;
base_z = 50;

wall = 4;
lid_thickness = 12;
inner_h = base_z - wall - lid_thickness;

// Proven printed M10-like thread fit copied from 2026-07-02_sample_screw_and_hole.scad:
// internal thread diameter = 10.4 mm, external bolt thread diameter = 9.8 mm.
bolt_d = 10;
bolt_pitch = 1.5;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
thread_leadin = 2;

lid_thread_d = bolt_d + thread_fit_clearance;
bolt_thread_d = bolt_d - bolt_fit_clearance;

// The mounting screw engages only 8 mm into the 12 mm lid. The modeled threaded
// shaft also includes the 10 mm bracket base thickness so the assembly can clamp.
mount_bolt_lid_engagement = 8;
lid_mount_thread_depth = 8.5;
lid_mount_thread_cut_overlap = 0.2;

bolt_head_d = 16;
bolt_head_h = 5;

// M20 fill ports are through-threaded in the lid.
fill_bolt_d = 20;
fill_bolt_pitch = 2.5;
fill_thread_d = fill_bolt_d + thread_fit_clearance;
fill_bolt_thread_d = fill_bolt_d - bolt_fit_clearance;
fill_bolt_thread_length = lid_thickness;
fill_bolt_head_d = 30;
fill_bolt_head_h = 8;

bracket_side_thickness = 10;
bracket_gap = 16;
bracket_side_depth = 30;
bracket_side_height = 50;
bracket_base_thickness = bracket_side_thickness;
bracket_base_width = 2 * bracket_side_thickness + bracket_gap;
bracket_base_depth = base_y;

mount_bolt_thread_length = bracket_base_thickness + mount_bolt_lid_engagement;
mount_bolt_clearance_d = lid_thread_d;

bracket_center_x = base_x / 2;
bracket_base_x_min = bracket_center_x - bracket_base_width / 2;
bracket_base_x_max = bracket_center_x + bracket_base_width / 2;
bracket_side_y_min = base_y / 2 - bracket_side_depth / 2;
bracket_side_y_max = bracket_side_y_min + bracket_side_depth;
bracket_side_left_x = bracket_center_x - bracket_gap / 2 - bracket_side_thickness;
bracket_side_right_x = bracket_center_x + bracket_gap / 2;

// Mounting bolts sit in the middle of the free front/back margins of the
// bracket base, centered on X.
mount_bolt_positions = [
    [bracket_center_x, bracket_side_y_min / 2],
    [bracket_center_x, (bracket_side_y_max + base_y) / 2]
];

// M20 fill ports sit in the middle of the lid areas left/right of the bracket
// base. They are through holes in the 12 mm lid.
fill_bolt_positions = [
    [bracket_base_x_min / 2, base_y / 2],
    [(bracket_base_x_max + base_x) / 2, base_y / 2]
];
fill_bolt_outer_edges_x = [
    fill_bolt_positions[0][0] - fill_thread_d / 2,
    fill_bolt_positions[1][0] + fill_thread_d / 2
];

// Side holes are 10 mm farther apart than in the previous 40 mm bracket. The
// old 6.4 mm edge clearance is preserved, making the holes closer to top/bottom.
old_bracket_side_height = 40;
old_bracket_hole_edge_gap =
    (old_bracket_side_height - 2 * mount_bolt_clearance_d) / 3;
bracket_side_hole_z_offsets = [
    old_bracket_hole_edge_gap + mount_bolt_clearance_d / 2,
    bracket_side_height - old_bracket_hole_edge_gap - mount_bolt_clearance_d / 2
];

// Two ribs are perpendicular to the long X side. One rib is perpendicular to
// the short Y side. At every intersection, both ribs get a full-height cutout
// with a 30 mm horizontal span, centered 15 mm to each side of the contact.
// Only the two outer pieces of the rib parallel to the long X side are
// trapezoids in X/Z side view, so the fill holes do not pour onto vertical rib
// walls.
// Other rib pieces are top-wide lid supports. Their sides curve inward, but
// every local segment keeps at least 50 degrees from the print bed.
rib_x_positions = [
    base_x / 3,
    2 * base_x / 3
];
rib_y_positions = [
    base_y / 2
];
rib_cutout_enabled = true;
rib_cutout_span = 30;
rib_cutout_overlap = 0.2;
rib_trapezoid_slice_h = 0.1;
rib_support_min_angle_from_bed = 50;
rib_support_curve_power = 1.5;
rib_support_steps = 6;
rib_support_slice_h = 0.15;
rib_support_min_bottom_span = wall;

function rib_support_max_run_per_side() =
    inner_h / tan(rib_support_min_angle_from_bed) / rib_support_curve_power;

function rib_support_run_per_side(top_span) =
    min(
        max(0, (top_span - rib_support_min_bottom_span) / 2),
        rib_support_max_run_per_side()
    );

function rib_support_bottom_span(top_span) =
    top_span - 2 * rib_support_run_per_side(top_span);

function rib_support_span_at(top_span, step) =
    rib_support_bottom_span(top_span)
    + 2
    * rib_support_run_per_side(top_span)
    * pow(step / rib_support_steps, rib_support_curve_power);

function rib_support_z_at(step) =
    wall + (inner_h - rib_support_slice_h) * step / rib_support_steps;

function rib_outer_fill_span_at(bottom_span, top_span, step) =
    bottom_span
    + (top_span - bottom_span)
    * pow(step / rib_support_steps, 1 / rib_support_curve_power);

// OpenSCAD 2021 has no native object/dictionary syntax, so this key/value list
// is the parts object. Change true/false by part name to export or inspect.
parts = [
    ["bottom", true],
    ["top_lid", false],
    ["front", true],
    ["back", true],
    ["left", true],
    ["right", true],
    ["ribs_x", true],
    ["ribs_y", true],
    ["bracket", true],
    ["mount_bolt_front", true],
    ["mount_bolt_back", true],
    ["fill_bolt_left", true],
    ["fill_bolt_right", true]
];

function part_enabled(name) =
    len([for (part = parts) if (part[0] == name && part[1]) part]) > 0;

function base_context_enabled() =
    part_enabled("bottom")
    || part_enabled("top_lid")
    || part_enabled("front")
    || part_enabled("back")
    || part_enabled("left")
    || part_enabled("right")
    || part_enabled("ribs_x")
    || part_enabled("ribs_y");

module enabled_part(name, color_value) {
    if (part_enabled(name)) {
        color(color_value)
            children();
    }
}

module lid_mount_threaded_hole(position) {
    translate([
        position[0],
        position[1],
        base_z - lid_mount_thread_depth
    ])
        metric_thread(
            diameter = lid_thread_d,
            pitch = bolt_pitch,
            length = lid_mount_thread_depth + lid_mount_thread_cut_overlap,
            internal = true,
            leadin = thread_leadin,
            test = preview_fast
        );
}

module fill_threaded_hole(position) {
    translate([
        position[0],
        position[1],
        base_z - lid_thickness - lid_mount_thread_cut_overlap / 2
    ])
        metric_thread(
            diameter = fill_thread_d,
            pitch = fill_bolt_pitch,
            length = lid_thickness + lid_mount_thread_cut_overlap,
            internal = true,
            leadin = thread_leadin,
            test = preview_fast
        );
}

module hex_head_bolt(thread_d, pitch, thread_length, head_d, head_h) {
    union() {
        metric_thread(
            diameter = thread_d,
            pitch = pitch,
            length = thread_length,
            internal = false,
            leadin = thread_leadin,
            test = preview_fast
        );

        translate([0, 0, thread_length])
            rotate([0, 0, 30])
                cylinder(d = head_d, h = head_h, $fn = 6);
    }
}

module mount_bolt() {
    hex_head_bolt(
        bolt_thread_d,
        bolt_pitch,
        mount_bolt_thread_length,
        bolt_head_d,
        bolt_head_h
    );
}

module fill_bolt() {
    hex_head_bolt(
        fill_bolt_thread_d,
        fill_bolt_pitch,
        fill_bolt_thread_length,
        fill_bolt_head_d,
        fill_bolt_head_h
    );
}

module placed_mount_bolt(position) {
    if (base_context_enabled() && part_enabled("bracket")) {
        translate([
            position[0],
            position[1],
            base_z + bracket_base_thickness - mount_bolt_thread_length
        ])
            mount_bolt();
    } else if (base_context_enabled()) {
        translate([
            position[0],
            position[1],
            base_z - mount_bolt_lid_engagement
        ])
            hex_head_bolt(
                bolt_thread_d,
                bolt_pitch,
                mount_bolt_lid_engagement,
                bolt_head_d,
                bolt_head_h
            );
    } else {
        mount_bolt();
    }
}

module placed_fill_bolt(position) {
    if (base_context_enabled()) {
        translate([
            position[0],
            position[1],
            base_z - fill_bolt_thread_length
        ])
            fill_bolt();
    } else {
        fill_bolt();
    }
}

module bracket_base(z_origin) {
    translate([bracket_base_x_min, 0, z_origin])
        difference() {
            cube([
                bracket_base_width,
                bracket_base_depth,
                bracket_base_thickness
            ]);

            for (position = mount_bolt_positions) {
                translate([
                    position[0] - bracket_base_x_min,
                    position[1],
                    -lid_mount_thread_cut_overlap / 2
                ])
                    cylinder(
                        d = mount_bolt_clearance_d,
                        h = bracket_base_thickness + lid_mount_thread_cut_overlap
                    );
            }
        }
}

module bracket_side(side_x, z_origin) {
    translate([
        side_x,
        bracket_side_y_min,
        z_origin + bracket_base_thickness
    ])
        difference() {
            cube([
                bracket_side_thickness,
                bracket_side_depth,
                bracket_side_height
            ]);

            for (hole_z = bracket_side_hole_z_offsets) {
                translate([
                    -lid_mount_thread_cut_overlap / 2,
                    bracket_side_depth / 2,
                    hole_z
                ])
                    rotate([0, 90, 0])
                        cylinder(
                            d = mount_bolt_clearance_d,
                            h = bracket_side_thickness + lid_mount_thread_cut_overlap
                        );
            }
        }
}

module bracket_at_z(z_origin) {
    bracket_base(z_origin);
    bracket_side(bracket_side_left_x, z_origin);
    bracket_side(bracket_side_right_x, z_origin);
}

module placed_bracket() {
    if (base_context_enabled()) {
        bracket_at_z(base_z);
    } else {
        bracket_at_z(0);
    }
}

module rib_support_y_span(x_pos, y_min, y_max) {
    top_span = y_max - y_min;
    y_center = (y_min + y_max) / 2;

    for (step = [0 : rib_support_steps - 1]) {
        hull() {
            translate([
                x_pos - wall / 2,
                y_center - rib_support_span_at(top_span, step) / 2,
                rib_support_z_at(step)
            ])
                cube([
                    wall,
                    rib_support_span_at(top_span, step),
                    rib_support_slice_h
                ]);

            translate([
                x_pos - wall / 2,
                y_center - rib_support_span_at(top_span, step + 1) / 2,
                rib_support_z_at(step + 1)
            ])
                cube([
                    wall,
                    rib_support_span_at(top_span, step + 1),
                    rib_support_slice_h
                ]);
        }
    }
}

module rib_support_x_span(y_pos, x_min, x_max) {
    top_span = x_max - x_min;
    x_center = (x_min + x_max) / 2;

    for (step = [0 : rib_support_steps - 1]) {
        hull() {
            translate([
                x_center - rib_support_span_at(top_span, step) / 2,
                y_pos - wall / 2,
                rib_support_z_at(step)
            ])
                cube([
                    rib_support_span_at(top_span, step),
                    wall,
                    rib_support_slice_h
                ]);

            translate([
                x_center - rib_support_span_at(top_span, step + 1) / 2,
                y_pos - wall / 2,
                rib_support_z_at(step + 1)
            ])
                cube([
                    rib_support_span_at(top_span, step + 1),
                    wall,
                    rib_support_slice_h
                ]);
        }
    }
}

module rib_x_plane(x_pos) {
    if (rib_cutout_enabled) {
        rib_support_y_span(
            x_pos,
            wall,
            rib_y_positions[0] - rib_cutout_span / 2
        );

        rib_support_y_span(
            x_pos,
            rib_y_positions[0] + rib_cutout_span / 2,
            base_y - wall
        );
    } else {
        rib_support_y_span(x_pos, wall, base_y - wall);
    }
}

module rib_y_outer_curved_trapezoid_segment(
    y_pos,
    x_bottom_min,
    x_bottom_max,
    x_top_min,
    x_top_max
) {
    bottom_span = x_bottom_max - x_bottom_min;
    top_span = x_top_max - x_top_min;
    left_side_locked = x_bottom_min == x_top_min;

    for (step = [0 : rib_support_steps - 1]) {
        span_a = rib_outer_fill_span_at(bottom_span, top_span, step);
        span_b = rib_outer_fill_span_at(bottom_span, top_span, step + 1);
        x_a = left_side_locked ? x_bottom_min : x_bottom_max - span_a;
        x_b = left_side_locked ? x_bottom_min : x_bottom_max - span_b;

        hull() {
            translate([x_a, y_pos - wall / 2, rib_support_z_at(step)])
                cube([span_a, wall, rib_support_slice_h]);

            translate([x_b, y_pos - wall / 2, rib_support_z_at(step + 1)])
                cube([span_b, wall, rib_support_slice_h]);
        }
    }
}

module rib_y_center_segment(y_pos) {
    x_min = rib_x_positions[0] + rib_cutout_span / 2;
    x_max = rib_x_positions[1] - rib_cutout_span / 2;

    rib_support_x_span(y_pos, x_min, x_max);
}

module rib_y_plane(y_pos) {
    if (rib_cutout_enabled) {
        rib_y_outer_curved_trapezoid_segment(
            y_pos,
            wall,
            rib_x_positions[0] - rib_cutout_span / 2,
            wall,
            fill_bolt_outer_edges_x[0]
        );

        rib_y_center_segment(y_pos);

        rib_y_outer_curved_trapezoid_segment(
            y_pos,
            rib_x_positions[1] + rib_cutout_span / 2,
            base_x - wall,
            fill_bolt_outer_edges_x[1],
            base_x - wall
        );
    } else {
        translate([wall, y_pos - wall / 2, wall])
            cube([base_x - 2 * wall, wall, inner_h]);
    }
}

module cube_base() {
    enabled_part("bottom", [0.35, 0.45, 0.62])
        cube([base_x, base_y, wall]);

    enabled_part("top_lid", [0.35, 0.45, 0.62])
        difference() {
            translate([0, 0, base_z - lid_thickness])
                cube([base_x, base_y, lid_thickness]);

            for (position = mount_bolt_positions) {
                lid_mount_threaded_hole(position);
            }

            for (position = fill_bolt_positions) {
                fill_threaded_hole(position);
            }
        }

    enabled_part("front", [0.50, 0.35, 0.52])
        translate([0, 0, wall])
            cube([base_x, wall, inner_h]);

    enabled_part("back", [0.50, 0.35, 0.52])
        translate([0, base_y - wall, wall])
            cube([base_x, wall, inner_h]);

    enabled_part("left", [0.35, 0.55, 0.45])
        translate([0, wall, wall])
            cube([wall, base_y - 2 * wall, inner_h]);

    enabled_part("right", [0.35, 0.55, 0.45])
        translate([base_x - wall, wall, wall])
            cube([wall, base_y - 2 * wall, inner_h]);

    enabled_part("ribs_x", [0.75, 0.55, 0.30])
        for (x_pos = rib_x_positions) {
            rib_x_plane(x_pos);
        }

    enabled_part("ribs_y", [0.80, 0.58, 0.34])
        for (y_pos = rib_y_positions) {
            rib_y_plane(y_pos);
        }
}

module iphone_15_pro_max_cube_holder() {
    cube_base();

    enabled_part("bracket", [0.35, 0.45, 0.62])
        placed_bracket();

    enabled_part("mount_bolt_front", [0.58, 0.60, 0.62])
        placed_mount_bolt(mount_bolt_positions[0]);

    enabled_part("mount_bolt_back", [0.58, 0.60, 0.62])
        placed_mount_bolt(mount_bolt_positions[1]);

    enabled_part("fill_bolt_left", [0.58, 0.60, 0.62])
        placed_fill_bolt(fill_bolt_positions[0]);

    enabled_part("fill_bolt_right", [0.58, 0.60, 0.62])
        placed_fill_bolt(fill_bolt_positions[1]);
}

iphone_15_pro_max_cube_holder();
