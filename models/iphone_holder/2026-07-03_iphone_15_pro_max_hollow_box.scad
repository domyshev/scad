// Hollow rectangular box based on iPhone 15 Pro Max dimensions.
//
// Apple iPhone 15 Pro Max official dimensions:
// - Height: 159.9 mm -> used here as external box length (X)
// - Width:   76.7 mm -> used here as external box width (Y)
// - Depth:    8.25 mm -> doubled here for external box height (Z = 16.5 mm)
//
// All box dimensions below are external dimensions.

$fn = 32;
preview_fast = $preview;

use <../../lib/core/threads/threads.scad>

iphone_15_pro_max_length = 159.9; // Apple "Height" dimension, used as box length
iphone_15_pro_max_width  = 76.7;  // Apple "Width" dimension, used as box width
iphone_15_pro_max_depth  = 8.25;  // Apple "Depth" dimension, two depths define box height

box_l = iphone_15_pro_max_length;
box_w = iphone_15_pro_max_width;
box_h = iphone_15_pro_max_depth * 2;

wall = 4;

// Proven printed M10 thread fit copied from 2026-07-02_sample_screw_and_hole.scad:
// internal thread diameter = 10.4 mm, external bolt thread diameter = 9.8 mm.
bolt_d = 10;
bolt_pitch = 1.5;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
thread_leadin = 2;

lid_thread_depth = wall;
lid_thread_cut_overlap = 0.2;
lid_thread_d = bolt_d + thread_fit_clearance;
bolt_thread_d = bolt_d - bolt_fit_clearance;

// Two threaded lid holes: the hole edge is 5 mm from the inner face of the
// long front side, and each hole center is 10 mm left/right from the rib axis.
lid_hole_edge_from_long_side = 5;
lid_hole_offset_from_rib = 10;
lid_hole_y = wall + lid_hole_edge_from_long_side + lid_thread_d / 2;
lid_hole_positions = [
    [box_l / 2 - lid_hole_offset_from_rib, lid_hole_y],
    [box_l / 2 + lid_hole_offset_from_rib, lid_hole_y]
];

bolt_thread_length = lid_thread_depth;
bolt_head_d = 16;
bolt_head_h = 5;
bolt_insert_z = box_h - bolt_thread_length;

// Center slot in the internal rib for fluid/air communication between chambers.
// The rib inner height is 8.5 mm, so the 10 mm slot dimension is used as width.
rib_slot_enabled = true;
rib_slot_width = 10;
rib_slot_cut_overlap = 0.2;

// OpenSCAD 2021 has no native object/dictionary syntax, so this key/value list
// is the parts object. Change true/false by part name to export or inspect sides.
parts = [
    ["bottom", true],
    ["top",    true],
    ["front",  true],
    ["back",   true],
    ["left",   true],
    ["right",  true],
    ["rib",    true],
    ["bolt_left_of_rib",  false],
    ["bolt_right_of_rib", true]
];

function part_enabled(name) =
    len([for (part = parts) if (part[0] == name && part[1]) part]) > 0;

module enabled_part(name, color_value) {
    if (part_enabled(name)) {
        color(color_value)
            children();
    }
}

module lid_threaded_hole(position) {
    translate([position[0], position[1], box_h - wall - lid_thread_cut_overlap / 2])
        metric_thread(
            diameter = lid_thread_d,
            pitch = bolt_pitch,
            length = lid_thread_depth + lid_thread_cut_overlap,
            internal = true,
            leadin = thread_leadin,
            test = preview_fast
        );
}

module hex_head_bolt() {
    union() {
        metric_thread(
            diameter = bolt_thread_d,
            pitch = bolt_pitch,
            length = bolt_thread_length,
            internal = false,
            leadin = thread_leadin,
            test = preview_fast
        );

        translate([0, 0, bolt_thread_length])
            rotate([0, 0, 30])
                cylinder(d = bolt_head_d, h = bolt_head_h, $fn = 6);
    }
}

module iphone_15_pro_max_hollow_box() {
    // bottom: 159.9 x 76.7 x 4 mm
    enabled_part("bottom", [0.35, 0.45, 0.62])
        cube([box_l, box_w, wall]);

    // top/lid: 159.9 x 76.7 x 4 mm, with two printed M10 threaded holes
    enabled_part("top", [0.35, 0.45, 0.62])
        difference() {
            translate([0, 0, box_h - wall])
                cube([box_l, box_w, wall]);

            for (position = lid_hole_positions) {
                lid_threaded_hole(position);
            }
        }

    // front: length matches iPhone height, wall thickness is 4 mm
    enabled_part("front", [0.50, 0.35, 0.52])
        translate([0, 0, wall])
            cube([box_l, wall, box_h - 2 * wall]);

    // back: length matches iPhone height, wall thickness is 4 mm
    enabled_part("back", [0.50, 0.35, 0.52])
        translate([0, box_w - wall, wall])
            cube([box_l, wall, box_h - 2 * wall]);

    // left: width span is between front/back walls, wall thickness is 4 mm
    enabled_part("left", [0.35, 0.55, 0.45])
        translate([0, wall, wall])
            cube([wall, box_w - 2 * wall, box_h - 2 * wall]);

    // right: width span is between front/back walls, wall thickness is 4 mm
    enabled_part("right", [0.35, 0.55, 0.45])
        translate([box_l - wall, wall, wall])
            cube([wall, box_w - 2 * wall, box_h - 2 * wall]);

    // rib: one internal cross rib, perpendicular to the long X side and
    // parallel to the short left/right end walls. The centered slot connects
    // the two chambers across the rib.
    enabled_part("rib", [0.75, 0.55, 0.30])
        difference() {
            translate([box_l / 2 - wall / 2, wall, wall])
                cube([wall, box_w - 2 * wall, box_h - 2 * wall]);

            if (rib_slot_enabled) {
                translate([
                    box_l / 2 - wall / 2 - rib_slot_cut_overlap / 2,
                    box_w / 2 - rib_slot_width / 2,
                    wall - rib_slot_cut_overlap / 2
                ])
                    cube([
                        wall + rib_slot_cut_overlap,
                        rib_slot_width,
                        box_h - 2 * wall + rib_slot_cut_overlap
                    ]);
            }
        }

    // Separate matching bolts for the two lid holes. In assembly view the
    // threaded shaft is sunk into the lid, so only the hex head protrudes.
    enabled_part("bolt_left_of_rib", [0.58, 0.60, 0.62])
        translate([lid_hole_positions[0][0], lid_hole_positions[0][1], bolt_insert_z])
            hex_head_bolt();

    enabled_part("bolt_right_of_rib", [0.58, 0.60, 0.62])
        translate([lid_hole_positions[1][0], lid_hole_positions[1][1], bolt_insert_z])
            hex_head_bolt();
}

iphone_15_pro_max_hollow_box();
