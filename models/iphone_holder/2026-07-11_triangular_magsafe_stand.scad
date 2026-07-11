// Two-frame triangular skeleton for the modular-link MagSafe stand.
//
// Each 80 mm side uses two 40 mm modular links. Adjacent segments alternate
// face-up / face-down so their repaired radial serrations physically mate.

use <2026-07-11_modular_link_concept.scad>

$fn = 72;

scene = "frame_pair"; // frame_pair, joint_spacer, frame_envelope, ballast_*
show_hardware = true;

frame_side = 80;
frame_depth = 90;
frame_inner_gap = 64.4;
frame_height = frame_side * sqrt(3) / 2;

frame_nodes = [
    [-40, 0],
    [-20, frame_height / 2],
    [0, frame_height],
    [20, frame_height / 2],
    [40, 0],
    [0, 0]
];

left_frame_reference_y = -32.2;
right_frame_reference_y = 45;

cross_rod_d = 4;
cross_rod_length = 105;
spacer_size = [10, 10];
spacer_corner_r = 2;
spacer_bore_d = 4.8;

ballast_profile = [
    [-45, -8],
    [45, -8],
    [32, 32],
    [-32, 32]
];
ballast_depth = 64;
ballast_corner_r = 3;
ballast_wall = 2.4;
ballast_bottom = 3;
ballast_sleeve_od = 10;
ballast_sleeve_bore_d = 4.8;
ballast_sleeve_length = frame_inner_gap;
ballast_end_load_zone = 4.5;
ballast_rail_depth = 1.3;
ballast_rail_clearance = 0.28;
ballast_lid_plate_h = 2.4;
ballast_pin_hole_d = 1.9;
ballast_collision_probe = 0.05;
ballast_epsilon = 0.02;

ballast_profile_side_run =
    ballast_profile[2][0] - ballast_profile[1][0];
ballast_profile_height =
    ballast_profile[2][1] - ballast_profile[1][1];
ballast_side_slope =
    -ballast_profile_side_run / ballast_profile_height;
ballast_side_wall_x =
    ballast_wall * sqrt(1 + ballast_side_slope * ballast_side_slope);
ballast_cavity_bottom_z = ballast_profile[0][1] + ballast_bottom;
ballast_lid_top_z = ballast_profile[2][1];
ballast_lid_bottom_z = ballast_lid_top_z - ballast_lid_plate_h;
ballast_rail_bottom_z = ballast_lid_bottom_z - ballast_rail_depth;
ballast_cavity_depth = ballast_depth - 2 * ballast_wall;

function ballast_outer_half_width(z_position) =
    ballast_profile[1][0] -
        ballast_side_slope * (z_position - ballast_profile[1][1]);

function ballast_inner_half_width(z_position) =
    ballast_outer_half_width(z_position) - ballast_side_wall_x;

ballast_lid_half_width =
    ballast_inner_half_width(ballast_lid_bottom_z) -
        ballast_rail_clearance;
ballast_lid_width = 2 * ballast_lid_half_width;
ballast_lid_min_y =
    -ballast_cavity_depth / 2 + ballast_rail_clearance;
ballast_lid_max_y =
    ballast_depth / 2 - ballast_rail_clearance;
ballast_lid_length = ballast_lid_max_y - ballast_lid_min_y;
ballast_lid_center_y =
    (ballast_lid_min_y + ballast_lid_max_y) / 2;
ballast_labyrinth_width =
    ballast_lid_width - 2 * ballast_rail_depth;
ballast_labyrinth_y =
    ballast_cavity_depth / 2 - ballast_rail_depth / 2;
ballast_pin_y = ballast_depth / 2 - ballast_end_load_zone / 3;

frame_color = "#10B981";
hardware_color = "#6B7280";
spacer_color = "#F59E0B";

assert(
    abs(frame_side / 2 - modular_link_pitch()) < 0.001,
    "Frame segments must match the modular-link pitch"
);
assert(
    abs(
        frame_depth -
            (frame_inner_gap + 2 * modular_link_stack_h())
    ) < 0.001,
    "Frame depth must equal the clear gap plus two link stacks"
);
assert(
    ballast_rail_depth > ballast_rail_clearance,
    "Lid rails must retain positive engagement after print clearance"
);

module frame_link(node_a, node_b, upper_layer = false) {
    dx = node_b[0] - node_a[0];
    dz = node_b[1] - node_a[1];
    angle = atan2(dz, dx);
    midpoint = [(node_a[0] + node_b[0]) / 2,
                (node_a[1] + node_b[1]) / 2];

    translate([midpoint[0], 0, midpoint[1]])
        rotate([0, -angle, 0])
            rotate([90, 0, 0])
                if (upper_layer)
                    translate([0, 0, modular_link_stack_h()])
                        rotate([180, 0, 0]) modular_link();
                else
                    modular_link();
}

module triangle_frame(y_reference) {
    translate([0, y_reference, 0])
        for (segment_index = [0 : len(frame_nodes) - 1])
            let(next_index = (segment_index + 1) % len(frame_nodes))
                frame_link(
                    frame_nodes[segment_index],
                    frame_nodes[next_index],
                    upper_layer = segment_index % 2 == 1
                );
}

module cross_rod(node) {
    translate([node[0], 0, node[1]])
        rotate([90, 0, 0])
            cylinder(
                d = cross_rod_d,
                h = cross_rod_length,
                center = true
            );
}

module frame_pair() {
    color(frame_color) {
        triangle_frame(left_frame_reference_y);
        triangle_frame(right_frame_reference_y);
    }

    if (show_hardware)
        for (node = frame_nodes)
            %color(hardware_color)
                cross_rod(node);
}

module rounded_rectangle_2d(size, corner_r) {
    offset(r = corner_r)
        square(
            [size[0] - 2 * corner_r, size[1] - 2 * corner_r],
            center = true
        );
}

module teardrop_2d(diameter) {
    radius = diameter / 2;
    tangent = radius / sqrt(2);

    union() {
        circle(d = diameter);
        polygon([
            [-tangent, tangent],
            [0, radius * sqrt(2)],
            [tangent, tangent]
        ]);
    }
}

module joint_spacer() {
    color(spacer_color)
        rotate([90, 0, 0])
            linear_extrude(
                height = frame_inner_gap,
                center = true,
                convexity = 6
            )
                difference() {
                    rounded_rectangle_2d(
                        spacer_size,
                        spacer_corner_r
                    );
                    teardrop_2d(spacer_bore_d);
                }
}

module extrude_xz(profile, depth) {
    rotate([90, 0, 0])
        linear_extrude(
            height = depth,
            center = true,
            convexity = 10
        )
            polygon(profile);
}

module ballast_outer(depth = ballast_depth) {
    rotate([90, 0, 0])
        linear_extrude(
            height = depth,
            center = true,
            convexity = 10
        )
            offset(r = ballast_corner_r)
                offset(delta = -ballast_corner_r)
                    polygon(ballast_profile);
}

module ballast_open_cavity() {
    rail_inner_half_width =
        ballast_inner_half_width(ballast_lid_bottom_z) -
            ballast_rail_depth;
    cavity_profile = [
        [
            -ballast_inner_half_width(ballast_cavity_bottom_z),
            ballast_cavity_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_cavity_bottom_z),
            ballast_cavity_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_rail_bottom_z),
            ballast_rail_bottom_z
        ],
        [
            rail_inner_half_width,
            ballast_rail_bottom_z
        ],
        [
            rail_inner_half_width,
            ballast_lid_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_top_z + ballast_epsilon
        ],
        [
            -ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_top_z + ballast_epsilon
        ],
        [
            -ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_bottom_z
        ],
        [
            -rail_inner_half_width,
            ballast_lid_bottom_z
        ],
        [
            -rail_inner_half_width,
            ballast_rail_bottom_z
        ],
        [
            -ballast_inner_half_width(ballast_rail_bottom_z),
            ballast_rail_bottom_z
        ]
    ];

    extrude_xz(
        cavity_profile,
        ballast_cavity_depth
    );
}

module ballast_fill_envelope() {
    fill_profile = [
        [
            -ballast_inner_half_width(ballast_cavity_bottom_z),
            ballast_cavity_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_cavity_bottom_z),
            ballast_cavity_bottom_z
        ],
        [
            ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_bottom_z
        ],
        [
            -ballast_inner_half_width(ballast_lid_bottom_z),
            ballast_lid_bottom_z
        ]
    ];

    extrude_xz(
        fill_profile,
        ballast_cavity_depth
    );
}

module ballast_sleeves(
    length = ballast_sleeve_length,
    diameter = ballast_sleeve_od
) {
    for (sleeve_x = [-40, 0, 40])
        translate([sleeve_x, 0, 0])
            rotate([90, 0, 0])
                cylinder(
                    d = diameter,
                    h = length,
                    center = true
                );
}

module ballast_sleeve_floor_webs() {
    web_bottom_z = ballast_cavity_bottom_z - ballast_epsilon;
    web_top_z = ballast_epsilon;
    web_height = web_top_z - web_bottom_z;

    for (sleeve_x = [-40, 0, 40])
        translate([
            sleeve_x,
            0,
            (web_bottom_z + web_top_z) / 2
        ])
            cube([
                ballast_end_load_zone,
                ballast_cavity_depth + 2 * ballast_epsilon,
                web_height
            ], center = true);
}

module ballast_sleeve_end_pads(
    overall_length = ballast_sleeve_length
) {
    pad_d = ballast_sleeve_od + 2 * ballast_wall;

    for (sleeve_x = [-40, 0, 40])
        for (end_sign = [-1, 1])
            translate([
                sleeve_x,
                end_sign *
                    (overall_length / 2 - ballast_end_load_zone / 2),
                0
            ])
                rotate([90, 0, 0])
                    cylinder(
                        d = pad_d,
                        h = ballast_end_load_zone,
                        center = true
                    );
}

module ballast_sleeve_bores(
    length = ballast_sleeve_length + 2 * ballast_epsilon
) {
    for (sleeve_x = [-40, 0, 40])
        translate([sleeve_x, 0, 0])
            rotate([90, 0, 0])
                linear_extrude(
                    height = length,
                    center = true,
                    convexity = 6
                )
                    teardrop_2d(ballast_sleeve_bore_d);
}

module ballast_lid_rails() {
    rail_outer_half_width =
        ballast_inner_half_width(ballast_rail_bottom_z) +
            ballast_wall;
    rail_inner_half_width =
        ballast_inner_half_width(ballast_lid_bottom_z) -
            ballast_rail_depth;
    rail_width = rail_outer_half_width - rail_inner_half_width;

    for (side_sign = [-1, 1])
        translate([
            side_sign *
                (rail_inner_half_width + rail_width / 2),
            0,
            ballast_rail_bottom_z + ballast_rail_depth / 2
        ])
            cube([
                rail_width,
                ballast_cavity_depth,
                ballast_rail_depth
            ], center = true);
}

module ballast_labyrinth_lip() {
    translate([
        0,
        ballast_labyrinth_y,
        ballast_rail_bottom_z +
            (ballast_rail_depth + ballast_epsilon) / 2
    ])
        cube([
            ballast_labyrinth_width,
            ballast_rail_depth,
            ballast_rail_depth + ballast_epsilon
        ], center = true);
}

module ballast_lid_entry_slot() {
    slot_min_y = ballast_cavity_depth / 2 - ballast_epsilon;
    slot_max_y = ballast_depth / 2 + ballast_epsilon;
    slot_depth = slot_max_y - slot_min_y;

    translate([
        0,
        (slot_min_y + slot_max_y) / 2,
        (ballast_lid_bottom_z - ballast_rail_clearance +
            ballast_lid_top_z + ballast_epsilon) / 2
    ])
        cube([
            ballast_lid_width + 2 * ballast_rail_clearance,
            slot_depth,
            ballast_lid_plate_h +
                ballast_rail_clearance + ballast_epsilon
        ], center = true);

    translate([
        0,
        (slot_min_y + slot_max_y) / 2,
        ballast_rail_bottom_z - ballast_rail_clearance / 2 +
            (ballast_rail_depth + ballast_rail_clearance +
                ballast_epsilon) / 2
    ])
        cube([
            ballast_labyrinth_width +
                2 * ballast_rail_clearance,
            slot_depth,
            ballast_rail_depth +
                ballast_rail_clearance + ballast_epsilon
        ], center = true);
}

module ballast_pin_hole() {
    translate([
        0,
        ballast_pin_y,
        ballast_lid_bottom_z + ballast_lid_plate_h / 2
    ])
        rotate([0, 90, 0])
            cylinder(
                d = ballast_pin_hole_d,
                h = 2 * ballast_outer_half_width(ballast_lid_bottom_z) +
                    2 * ballast_epsilon,
                center = true
            );
}

module ballast_cassette_body(
    sleeve_length = ballast_sleeve_length
) {
    difference() {
        union() {
            difference() {
                ballast_outer();
                ballast_open_cavity();
            }

            ballast_sleeves(sleeve_length);
            ballast_sleeve_floor_webs();
            ballast_sleeve_end_pads(sleeve_length);
        }

        ballast_sleeve_bores(sleeve_length + 2 * ballast_epsilon);
        ballast_lid_entry_slot();
        ballast_pin_hole();
    }
}

module ballast_cassette_lid() {
    difference() {
        union() {
            translate([
                0,
                ballast_lid_center_y,
                ballast_lid_bottom_z + ballast_lid_plate_h / 2
            ])
                cube([
                    ballast_lid_width,
                    ballast_lid_length,
                    ballast_lid_plate_h
                ], center = true);

            ballast_labyrinth_lip();
        }

        ballast_pin_hole();
    }
}

module ballast_void() {
    difference() {
        ballast_fill_envelope();

        union() {
            ballast_sleeves(
                diameter = ballast_sleeve_od + 2 * ballast_epsilon
            );
            ballast_sleeve_floor_webs();
            ballast_sleeve_end_pads();
            ballast_lid_rails();
            ballast_labyrinth_lip();
        }
    }
}

module frame_ballast_overlap() {
    collision_sleeve_length =
        ballast_sleeve_length - 2 * ballast_collision_probe;

    intersection() {
        union() {
            triangle_frame(left_frame_reference_y);
            triangle_frame(right_frame_reference_y);
        }

        union() {
            ballast_cassette_body(collision_sleeve_length);
            ballast_cassette_lid();
        }
    }
}

if (scene == "frame_pair") {
    frame_pair();
} else if (scene == "joint_spacer") {
    joint_spacer();
} else if (scene == "frame_envelope") {
    frame_pair();
} else if (scene == "ballast_body") {
    translate([0, 0, -ballast_profile[0][1]])
        ballast_cassette_body();
} else if (scene == "ballast_lid") {
    translate([0, 0, ballast_lid_top_z])
        rotate([180, 0, 0])
            ballast_cassette_lid();
} else if (scene == "ballast_void") {
    ballast_void();
} else if (scene == "frame_ballast_overlap") {
    frame_ballast_overlap();
} else {
    assert(false, str("Unknown scene: ", scene));
}
