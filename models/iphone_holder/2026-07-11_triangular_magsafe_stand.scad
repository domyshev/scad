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
ballast_wall_contact_probe = 0.01;
ballast_epsilon = 0.02;

puck_preset = "a2580_a3250"; // a2580_a3250, a2140, custom
puck_d = 55.50;
puck_h = 4.37;

magsafe_cup_od = 60;
magsafe_back_wall = 2.4;
magsafe_diametral_clearance = 0.35;
magsafe_face_proud = 0.4;
magsafe_cable_slot = 4.1;
magsafe_cable_straight_length = 20;
magsafe_cable_bend_radius = 12;
magsafe_cable_guide_wall = 2;
magsafe_detent_width = 5;
magsafe_detent_depth = 1.2;
magsafe_detent_height = 1.4;

magsafe_center = [15, 0, 96];
magsafe_face_angle = 75;
apex_tube_od = 10;
apex_tube_bore_d = 4.8;
apex_tube_length = frame_inner_gap;
apex_key_clearance = 0.2;
apex_key_arm_width = 2.4;
apex_far_layer_face = frame_inner_gap / 2 +
    modular_link_stack_h() - modular_link_body_h();
holder_collision_probe = 0.05;

phone_height = 165;
phone_width = 80;
phone_thickness = 12;
phone_table_clearance = 8;

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

function ballast_lid_half_width_at(z_position) =
    ballast_inner_half_width(z_position) - ballast_rail_clearance;

ballast_lid_half_width =
    ballast_lid_half_width_at(ballast_lid_bottom_z);
ballast_lid_top_half_width =
    ballast_lid_half_width_at(ballast_lid_top_z);
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
assert(
    magsafe_cup_od <= 60,
    "MagSafe cup outer diameter must not exceed 60 mm"
);
assert(
    apex_tube_length == frame_inner_gap,
    "Apex cross-tube must exactly span the 64.4 mm inner gap"
);

function active_puck_d() =
    puck_preset == "a2140" ? 55.90 :
    puck_preset == "custom" ? puck_d :
    55.50;

function active_puck_h() =
    puck_preset == "a2140" ? 5.30 :
    puck_preset == "custom" ? puck_h :
    4.37;

function magsafe_cavity_diameter(selected_puck_d) =
    selected_puck_d + magsafe_diametral_clearance;

function magsafe_recess_depth(selected_puck_h) =
    selected_puck_h - magsafe_face_proud;

function magsafe_cup_depth(selected_puck_h) =
    magsafe_back_wall + magsafe_recess_depth(selected_puck_h);

function magsafe_puck_face_z(selected_puck_h) =
    magsafe_back_wall + selected_puck_h;

function magsafe_print_lift(selected_puck_h) =
    magsafe_cable_bend_radius + selected_puck_h / 2;

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
            ballast_inner_half_width(
                ballast_lid_top_z + ballast_epsilon
            ),
            ballast_lid_top_z + ballast_epsilon
        ],
        [
            -ballast_inner_half_width(
                ballast_lid_top_z + ballast_epsilon
            ),
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
    slot_bottom_z = ballast_lid_bottom_z - ballast_rail_clearance;
    slot_top_z = ballast_lid_top_z + ballast_epsilon;
    slot_bottom_half_width =
        ballast_inner_half_width(ballast_lid_bottom_z);
    slot_top_half_width =
        ballast_inner_half_width(slot_top_z);
    slot_profile = [
        [-slot_bottom_half_width, slot_bottom_z],
        [slot_bottom_half_width, slot_bottom_z],
        [slot_bottom_half_width, ballast_lid_bottom_z],
        [slot_top_half_width, slot_top_z],
        [-slot_top_half_width, slot_top_z],
        [-slot_bottom_half_width, ballast_lid_bottom_z]
    ];

    translate([0, (slot_min_y + slot_max_y) / 2, 0])
        extrude_xz(slot_profile, slot_depth);

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

module ballast_min_wall_keepout() {
    keepout_profile = [
        [
            ballast_inner_half_width(ballast_lid_bottom_z) +
                ballast_wall_contact_probe,
            ballast_lid_bottom_z
        ],
        [
            ballast_outer_half_width(ballast_lid_bottom_z) +
                ballast_wall,
            ballast_lid_bottom_z
        ],
        [
            ballast_outer_half_width(ballast_lid_top_z) +
                ballast_wall,
            ballast_lid_top_z
        ],
        [
            ballast_inner_half_width(ballast_lid_top_z) +
                ballast_wall_contact_probe,
            ballast_lid_top_z
        ]
    ];

    extrude_xz(
        keepout_profile,
        ballast_depth + 2 * ballast_epsilon
    );

    mirror([1, 0, 0])
        extrude_xz(
            keepout_profile,
            ballast_depth + 2 * ballast_epsilon
        );
}

module ballast_min_wall_overlap() {
    intersection() {
        ballast_min_wall_keepout();

        union() {
            ballast_open_cavity();
            ballast_lid_entry_slot();
        }
    }
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
    lid_profile = [
        [-ballast_lid_half_width, ballast_lid_bottom_z],
        [ballast_lid_half_width, ballast_lid_bottom_z],
        [ballast_lid_top_half_width, ballast_lid_top_z],
        [-ballast_lid_top_half_width, ballast_lid_top_z]
    ];

    difference() {
        union() {
            translate([0, ballast_lid_center_y, 0])
                extrude_xz(lid_profile, ballast_lid_length);

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

module magsafe_cup_outer(selected_puck_h = active_puck_h()) {
    cylinder(
        d = magsafe_cup_od,
        h = magsafe_cup_depth(selected_puck_h)
    );
}

module magsafe_cavity_cutout(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    translate([0, 0, magsafe_back_wall])
        cylinder(
            d = magsafe_cavity_diameter(selected_puck_d),
            h = magsafe_recess_depth(selected_puck_h) +
                ballast_epsilon
        );
}

module magsafe_cavity_probe(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    intersection() {
        magsafe_cup_outer(selected_puck_h);
        magsafe_cavity_cutout(selected_puck_d, selected_puck_h);
    }
}

module magsafe_radial_slot_cutout(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cavity_radius = magsafe_cavity_diameter(selected_puck_d) / 2;
    slot_run = magsafe_cup_od / 2 - cavity_radius +
        2 * ballast_epsilon;

    translate([
        cavity_radius - ballast_epsilon,
        -magsafe_cable_slot / 2,
        -ballast_epsilon
    ])
        cube([
            slot_run,
            magsafe_cable_slot,
            magsafe_cup_depth(selected_puck_h) +
                2 * ballast_epsilon
        ]);
}

module magsafe_cable_slot_probe(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    intersection() {
        magsafe_cup_outer(selected_puck_h);
        magsafe_radial_slot_cutout(
            selected_puck_d,
            selected_puck_h
        );
    }
}

module magsafe_detent_tabs(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cavity_radius = magsafe_cavity_diameter(selected_puck_d) / 2;
    detent_z = magsafe_cup_depth(selected_puck_h) -
        magsafe_detent_height / 2 - 0.25;

    for (detent_angle = [60, 180, 300])
        rotate([0, 0, detent_angle])
            translate([
                cavity_radius - magsafe_detent_depth / 2 + 0.25,
                0,
                detent_z
            ])
                cube([
                    magsafe_detent_depth,
                    magsafe_detent_width,
                    magsafe_detent_height
                ], center = true);
}

module magsafe_cup(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    assert(
        magsafe_cavity_diameter(selected_puck_d) < magsafe_cup_od,
        "Selected MagSafe puck leaves no cup wall"
    );
    assert(
        magsafe_recess_depth(selected_puck_h) > 0,
        "Selected MagSafe puck is too thin for the proud-face allowance"
    );

    difference() {
        union() {
            difference() {
                magsafe_cup_outer(selected_puck_h);
                magsafe_cavity_cutout(
                    selected_puck_d,
                    selected_puck_h
                );
            }

            magsafe_detent_tabs(
                selected_puck_d,
                selected_puck_h
            );
        }

        magsafe_radial_slot_cutout(
            selected_puck_d,
            selected_puck_h
        );
    }
}

module magsafe_fit_gauge(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    magsafe_cup(selected_puck_d, selected_puck_h);
}

module quarter_annulus_2d(inner_radius, outer_radius) {
    intersection() {
        difference() {
            circle(r = outer_radius);
            circle(r = inner_radius);
        }

        square([outer_radius, outer_radius]);
    }
}

module magsafe_cable_straight_clearance(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cable_center_z = magsafe_back_wall + selected_puck_h / 2;

    translate([
        selected_puck_d / 2,
        -magsafe_cable_slot / 2,
        cable_center_z - magsafe_cable_slot / 2
    ])
        cube([
            magsafe_cable_straight_length,
            magsafe_cable_slot,
            magsafe_cable_slot
        ]);
}

module magsafe_cable_bend_clearance(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cable_center_z = magsafe_back_wall + selected_puck_h / 2;
    bend_center_x = selected_puck_d / 2 +
        magsafe_cable_straight_length;
    bend_center_z = cable_center_z - magsafe_cable_bend_radius;

    translate([bend_center_x, 0, bend_center_z])
        rotate([90, 0, 0])
            linear_extrude(
                height = magsafe_cable_slot,
                center = true,
                convexity = 6
            )
                quarter_annulus_2d(
                    magsafe_cable_bend_radius -
                        magsafe_cable_slot / 2,
                    magsafe_cable_bend_radius +
                        magsafe_cable_slot / 2
                );
}

module magsafe_cable_straight_cradle(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cable_center_z = magsafe_back_wall + selected_puck_h / 2;
    outer_width = magsafe_cable_slot +
        2 * magsafe_cable_guide_wall;

    difference() {
        translate([
            selected_puck_d / 2 - ballast_epsilon,
            -outer_width / 2,
            cable_center_z - outer_width / 2
        ])
            cube([
                magsafe_cable_straight_length + 0.4,
                outer_width,
                outer_width
            ]);

        magsafe_cable_straight_clearance(
            selected_puck_d,
            selected_puck_h
        );

        translate([
            selected_puck_d / 2 - 1,
            -outer_width,
            cable_center_z + magsafe_cable_slot / 2
        ])
            cube([
                magsafe_cable_straight_length + 2,
                2 * outer_width,
                outer_width
            ]);
    }
}

module magsafe_cable_bend_guide(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    cable_center_z = magsafe_back_wall + selected_puck_h / 2;
    bend_center_x = selected_puck_d / 2 +
        magsafe_cable_straight_length;
    bend_center_z = cable_center_z - magsafe_cable_bend_radius;
    outer_half_width = magsafe_cable_slot / 2 +
        magsafe_cable_guide_wall;

    difference() {
        translate([bend_center_x, 0, bend_center_z])
            rotate([90, 0, 0])
                linear_extrude(
                    height = 2 * outer_half_width,
                    center = true,
                    convexity = 6
                )
                    quarter_annulus_2d(
                        magsafe_cable_bend_radius - outer_half_width,
                        magsafe_cable_bend_radius + outer_half_width
                    );

        magsafe_cable_bend_clearance(
            selected_puck_d,
            selected_puck_h
        );

        translate([
            bend_center_x - 1,
            magsafe_cable_slot / 2,
            bend_center_z - 1
        ])
            cube([
                magsafe_cable_bend_radius +
                    outer_half_width + 2,
                outer_half_width + 1,
                magsafe_cable_bend_radius +
                    outer_half_width + 2
            ]);
    }
}

module magsafe_open_cable_guide(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    union() {
        magsafe_cable_straight_cradle(
            selected_puck_d,
            selected_puck_h
        );
        magsafe_cable_bend_guide(
            selected_puck_d,
            selected_puck_h
        );
    }
}

module magsafe_pose() {
    translate(magsafe_center)
        rotate([0, 90 + (90 - magsafe_face_angle), 0])
            children();
}

module magsafe_cup_assembly(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    magsafe_pose()
        translate([
            0,
            0,
            -magsafe_puck_face_z(selected_puck_h)
        ])
            union() {
                magsafe_cup(selected_puck_d, selected_puck_h);
                magsafe_open_cable_guide(
                    selected_puck_d,
                    selected_puck_h
                );
            }
}

module apex_cross_tube(contact_relief = 0) {
    tube_length = apex_tube_length - 2 * contact_relief;

    translate([0, 0, frame_height])
        rotate([90, 0, 0])
            difference() {
                cylinder(d = apex_tube_od, h = tube_length, center = true);
                cylinder(
                    d = apex_tube_bore_d,
                    h = tube_length + 2 * ballast_epsilon,
                    center = true
                );
            }
}

function apex_key_arm_point(
    link_side,
    run,
    surface_clearance = apex_key_clearance
) = [
    link_side * (
        run / 2 -
        sqrt(3) / 2 * (
            modular_joint_d() / 2 +
            surface_clearance +
            apex_key_arm_width / 2
        )
    ),
    frame_height - sqrt(3) / 2 * run -
        (
            modular_joint_d() / 2 +
            surface_clearance +
            apex_key_arm_width / 2
        ) / 2
];

module apex_key_arm_profile(
    link_side,
    surface_clearance = apex_key_clearance
) {
    hull()
        for (run = [20, 30])
            translate(apex_key_arm_point(
                link_side,
                run,
                surface_clearance
            ))
                circle(d = apex_key_arm_width);
}

module apex_key_arm(
    link_side,
    y_start,
    y_stop,
    surface_clearance = apex_key_clearance
) {
    translate([0, (y_start + y_stop) / 2, 0])
        rotate([90, 0, 0])
            linear_extrude(
                height = abs(y_stop - y_start),
                center = true,
                convexity = 4
            )
                apex_key_arm_profile(
                    link_side,
                    surface_clearance
                );
}

module apex_key_stem(frame_side) {
    stem_center_y = frame_side * (frame_inner_gap / 2 - 1.2);

    translate([0, stem_center_y, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 2.2, center = true, convexity = 4)
                hull()
                    for (stem_z = [48, frame_height - 3.8])
                        translate([0, stem_z])
                            circle(d = 4.2);
}

module apex_key(frame_side = -1, contact_probe = false) {
    gap_start = frame_side * (frame_inner_gap / 2 - 2.0);
    near_face = frame_inner_gap / 2;
    far_face = apex_far_layer_face;
    stop_allowance = contact_probe ? -0.08 : apex_key_clearance;
    surface_allowance = contact_probe ? -0.08 : apex_key_clearance;
    near_stop = frame_side * (near_face - stop_allowance);
    far_stop = frame_side * (far_face - stop_allowance);
    near_link_side = -frame_side;
    far_link_side = frame_side;

    union() {
        apex_key_arm(
            near_link_side,
            gap_start,
            near_stop,
            surface_allowance
        );
        apex_key_arm(
            far_link_side,
            gap_start,
            far_stop,
            surface_allowance
        );

        if (!contact_probe)
            apex_key_stem(frame_side);
    }
}

module bridge_gusset(y_position, selected_puck_h) {
    hull() {
        translate([0, y_position, frame_height + 2.2])
            cube([6, 7, 5], center = true);

        magsafe_pose()
            translate([
                20,
                y_position,
                -magsafe_puck_face_z(selected_puck_h) +
                    magsafe_back_wall / 2
            ])
                cube([5, 7, magsafe_back_wall], center = true);
    }
}

module magsafe_bridge_holder(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h(),
    contact_relief = 0
) {
    union() {
        magsafe_cup_assembly(selected_puck_d, selected_puck_h);
        apex_cross_tube(contact_relief);
        apex_key(-1);
        apex_key(1);

        for (gusset_y = [-18, 18])
            bridge_gusset(gusset_y, selected_puck_h);
    }
}

module magsafe_bridge_holder_print(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    // Inverse face pose puts the back ribs and open guide in their support-free
    // orientation; the exact lift lands the lowest guide/rib edge on the bed.
    translate([0, 0, magsafe_print_lift(selected_puck_h)])
        rotate([0, -(90 + (90 - magsafe_face_angle)), 0])
            translate(-magsafe_center)
                magsafe_bridge_holder(
                    selected_puck_d,
                    selected_puck_h
                );
}

module phone_envelope() {
    magsafe_pose()
        translate([
            -phone_height / 2,
            -phone_width / 2,
            0
        ])
            cube([
                phone_height,
                phone_width,
                phone_thickness
            ]);
}

module phone_table_overlap() {
    intersection() {
        phone_envelope();

        translate([-200, -200, -1])
            cube([
                400,
                400,
                phone_table_clearance + holder_collision_probe + 1
            ]);
    }
}

module frame_holder_overlap() {
    intersection() {
        union() {
            triangle_frame(left_frame_reference_y);
            triangle_frame(right_frame_reference_y);
        }

        magsafe_bridge_holder(
            contact_relief = holder_collision_probe
        );
    }
}

module apex_key_contact_probe() {
    intersection() {
        union() {
            triangle_frame(left_frame_reference_y);
            triangle_frame(right_frame_reference_y);
        }

        union() {
            apex_key(-1, contact_probe = true);
            apex_key(1, contact_probe = true);
        }
    }
}

module magsafe_face_plane_probe() {
    magsafe_pose()
        cube([20, 4, 0.05], center = true);
}

module stand_spacers(offset_y = 0) {
    for (node_index = [1, 3])
        let(node = frame_nodes[node_index])
            translate([node[0], offset_y, node[1]])
                joint_spacer();
}

module magsafe_puck_preview(
    selected_puck_d = active_puck_d(),
    selected_puck_h = active_puck_h()
) {
    magsafe_pose()
        translate([
            0,
            0,
            -magsafe_puck_face_z(selected_puck_h) + magsafe_back_wall
        ])
            cylinder(d = selected_puck_d, h = selected_puck_h);
}

module stand_assembly(
    exploded = 0,
    include_hardware = true,
    include_phone = true
) {
    frame_spread = exploded;
    holder_lift = exploded * 0.7;
    lid_lift = exploded * 0.45;
    cassette_drop = exploded * 0.35;

    color(frame_color) {
        translate([0, -frame_spread, 0])
            triangle_frame(left_frame_reference_y);
        translate([0, frame_spread, 0])
            triangle_frame(right_frame_reference_y);
    }

    color("#334155")
        translate([0, 0, -cassette_drop])
            ballast_cassette_body();

    color("#64748B")
        translate([0, 0, lid_lift])
            ballast_cassette_lid();

    color(spacer_color)
        stand_spacers();

    color("#2563EB")
        translate([0, 0, holder_lift])
            magsafe_bridge_holder();

    color("#F8FAFC")
        translate([0, 0, holder_lift])
            magsafe_puck_preview();

    if (include_hardware)
        color(hardware_color)
            for (node = frame_nodes)
                cross_rod(node);

    if (include_phone)
        color([0.12, 0.15, 0.20, 0.32])
            translate([0, 0, holder_lift])
                phone_envelope();
}

module stand_preview() {
    stand_assembly();
}

module stand_exploded() {
    stand_assembly(exploded = 20, include_phone = false);
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
} else if (scene == "ballast_min_wall_overlap") {
    ballast_min_wall_overlap();
} else if (scene == "magsafe_fit_gauge") {
    magsafe_fit_gauge();
} else if (scene == "magsafe_bridge_holder") {
    magsafe_bridge_holder_print();
} else if (scene == "magsafe_cup_envelope") {
    magsafe_cup_outer();
} else if (scene == "magsafe_cavity_probe") {
    magsafe_cavity_probe();
} else if (scene == "magsafe_cable_slot_probe") {
    magsafe_cable_slot_probe();
} else if (scene == "magsafe_cable_straight_probe") {
    magsafe_cable_straight_clearance();
} else if (scene == "magsafe_cable_bend_probe") {
    magsafe_cable_bend_clearance();
} else if (scene == "magsafe_detent_probe") {
    magsafe_detent_tabs();
} else if (scene == "magsafe_face_plane_probe") {
    magsafe_face_plane_probe();
} else if (scene == "phone_envelope") {
    phone_envelope();
} else if (scene == "phone_table_overlap") {
    phone_table_overlap();
} else if (scene == "frame_holder_overlap") {
    frame_holder_overlap();
} else if (scene == "apex_key_contact_probe") {
    apex_key_contact_probe();
} else if (scene == "stand_preview") {
    stand_preview();
} else if (scene == "stand_exploded") {
    stand_exploded();
} else {
    assert(false, str("Unknown scene: ", scene));
}
