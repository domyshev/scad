// Small printable lock prototypes for the smart mechanical block concept.
//
// Each scene exports one printable part. The parts are intentionally small
// fit coupons: big enough to test the lock by hand, but cheap to print.

$fn = 48;

prototype = 1;
part = "dovetail_male";

fit = 0.35;
loose_fit = 0.45;
block_l = 28;
block_w = 18;
block_h = 8;

function known_part(prototype_number, part_name) =
    (prototype_number == 1 &&
        (part_name == "dovetail_male" ||
            part_name == "dovetail_socket")) ||
    (prototype_number == 2 &&
        (part_name == "bayonet_plug" ||
            part_name == "bayonet_socket")) ||
    (prototype_number == 3 &&
        (part_name == "snap_hook" ||
            part_name == "snap_socket")) ||
    (prototype_number == 4 &&
        (part_name == "wedge_left" ||
            part_name == "wedge_right" ||
            part_name == "wedge_key")) ||
    (prototype_number == 5 &&
        (part_name == "t_slider" ||
            part_name == "t_track")) ||
    (prototype_number == 6 &&
        (part_name == "split_pin_male" ||
            part_name == "split_pin_socket")) ||
    (prototype_number == 7 &&
        (part_name == "thread_plug" ||
            part_name == "thread_socket")) ||
    (prototype_number == 8 &&
        (part_name == "detent_slider" ||
            part_name == "detent_track")) ||
    (prototype_number == 9 &&
        (part_name == "cam_clamp_body" ||
            part_name == "cam_lever" ||
            part_name == "cam_pin")) ||
    (prototype_number == 10 &&
        (part_name == "rack_bar" ||
            part_name == "rack_pawl"));

module block(l = block_l, w = block_w, h = block_h) {
    translate([-l / 2, -w / 2, 0])
        cube([l, w, h]);
}

module prism_x(length, yz_points) {
    rotate([0, 90, 0])
        linear_extrude(height = length, center = true)
            polygon([for (point = yz_points) [-point[1], point[0]]]);
}

module round_pin_x(length, diameter) {
    rotate([0, 90, 0])
        cylinder(d = diameter, h = length, center = true);
}

module round_pin_y(length, diameter) {
    rotate([90, 0, 0])
        cylinder(d = diameter, h = length, center = true);
}

module teardrop_hole_x(length, diameter) {
    union() {
        round_pin_x(length, diameter);
        translate([0, 0, diameter * 0.22])
            prism_x(
                length,
                [
                    [-diameter / 2, 0],
                    [diameter / 2, 0],
                    [0, diameter * 0.78]
                ]
            );
    }
}

module coarse_two_start_thread(length = 8, outer_d = 10, clearance = 0) {
    pitch = 2.4;
    core_d = outer_d - 1.7 + clearance;
    ridge_depth = 1.05 + clearance / 2;
    ridge_width = 0.88 + clearance / 3;
    slice_count = ceil(length / pitch * 28);

    union() {
        cylinder(d = core_d, h = length);

        for (phase = [0, 180])
            rotate([0, 0, phase])
                linear_extrude(
                    height = length,
                    twist = 360 * length / pitch,
                    slices = slice_count,
                    convexity = 8
                )
                    translate([core_d / 2 - 0.22, -ridge_width / 2])
                        square([ridge_depth + 0.22, ridge_width]);
    }
}

module dovetail_male() {
    union() {
        block();
        prism_x(
            block_l - 4,
            [
                [-4.0, block_h - 0.1],
                [4.0, block_h - 0.1],
                [6.0, block_h + 4.0],
                [-6.0, block_h + 4.0]
            ]
        );
    }
}

module dovetail_socket() {
    difference() {
        block();
        prism_x(
            block_l + 0.4,
            [
                [-(4.0 + fit), -0.1],
                [4.0 + fit, -0.1],
                [6.0 + fit, 4.35],
                [-(6.0 + fit), 4.35]
            ]
        );
    }
}

module bayonet_plug() {
    union() {
        block(24, 24, 5);
        translate([0, 0, 4.9])
            cylinder(d = 7.8, h = 6.2);
        translate([0, 0, 8])
            cube([18, 4.0, 2.4], center = true);
        translate([0, 0, 10.9])
            cylinder(d1 = 7.8, d2 = 6.4, h = 1.5);
    }
}

module bayonet_socket() {
    difference() {
        block(24, 24, 9);

        translate([0, 0, -0.1])
            cylinder(d = 8.5, h = 9.2);

        // Vertical lug entry slots from the top.
        translate([0, 0, 5.1])
            cube([20 + loose_fit, 4.8 + loose_fit, 8.2], center = true);

        // Quarter-turn retention pocket below the top skin.
        translate([0, 0, 3.6])
            cube([4.8 + loose_fit, 20 + loose_fit, 3.0], center = true);

        // Relief at the stop so the lugs seat without grinding.
        for (angle = [90, 270])
            rotate([0, 0, angle])
                translate([0, 8.5, 3.5])
                    cylinder(d = 5.2, h = 3.2, center = true);
    }
}

module snap_hook() {
    union() {
        block(24, 18, 6);

        // Flexible cantilever tongue, printed flat and flexing vertically.
        translate([10.5, -3.2, 5.9])
            cube([12, 6.4, 1.35]);

        translate([21.7, -3.2, 5.9])
            prism_x(
                2.4,
                [
                    [-3.2, 0],
                    [3.2, 0],
                    [3.2, 2.8],
                    [-3.2, 1.15]
                ]
            );
    }
}

module snap_socket() {
    difference() {
        block(24, 18, 8);

        translate([-12.1, -3.8, 5.5])
            cube([13.5, 7.6, 2.2]);

        translate([-2.2, -4.2, 5.6])
            cube([2.4, 8.4, 3.0]);
    }
}

module wedge_receiver(left_side = true) {
    difference() {
        block(24, 18, 8);

        translate([0, 0, 4])
            prism_x(
                25,
                [
                    [-2.7, -2.0],
                    [2.7, -2.0],
                    [4.6, 2.3],
                    [-4.6, 2.3]
                ]
            );

        translate([0, left_side ? 6.5 : -6.5, 3.8])
            cube([25, 3.0, 3.5], center = true);
    }
}

module wedge_key() {
    prism_x(
        30,
        [
            [-2.3, 0],
            [2.3, 0],
            [4.0, 3.8],
            [-4.0, 3.8]
        ]
    );

    translate([-17, -5, 0])
        cube([3, 10, 4.2]);
}

module t_slider() {
    union() {
        block();
        translate([0, 0, block_h])
            cube([block_l - 4, 4.0, 4.2], center = true);
        translate([0, 0, block_h + 3.0])
            cube([block_l - 4, 10.0, 2.4], center = true);
    }
}

module t_track() {
    difference() {
        block();
        translate([0, 0, -0.1])
            cube([block_l + 0.4, 4.0 + fit, 4.9], center = true);
        translate([0, 0, 2.9])
            cube([block_l + 0.4, 10.0 + fit, 3.0], center = true);
    }
}

module split_pin_male() {
    difference() {
        union() {
            block(22, 18, 6);

            for (z_offset = [2.2, 4.8]) {
                translate([10.9, 0, z_offset])
                    cube([9.2, 3.2, 1.4], center = true);

                translate([15.3, 0, z_offset])
                    cube([2.4, 4.8, 1.8], center = true);
            }
        }

        // Split gap lets each printed pin compress while entering the socket.
        translate([12.5, -0.45, 1.2])
            cube([8.2, 0.9, 4.8]);
    }
}

module split_pin_socket() {
    difference() {
        block(22, 18, 8);

        for (z_offset = [2.2, 4.8]) {
            translate([-11.1, 0, z_offset])
                cube([10.2, 3.8 + fit, 1.9 + fit], center = true);

            translate([-5.9, 0, z_offset])
                cube([2.5, 5.4 + fit, 2.2 + fit], center = true);
        }
    }
}

module thread_plug() {
    union() {
        block(22, 22, 5);
        translate([0, 0, 4.9])
            coarse_two_start_thread(length = 8.2, outer_d = 9.8);
    }
}

module thread_socket() {
    difference() {
        block(22, 22, 10);
        translate([0, 0, -0.1])
            coarse_two_start_thread(
                length = 10.2,
                outer_d = 9.8,
                clearance = 0.45
            );
    }
}

module detent_slider() {
    union() {
        block(24, 16, 5);

        translate([0, 0, 5])
            cube([22, 6, 2.0], center = true);

        translate([0, 0, 7.1])
            cube([20, 2.0, 2.8], center = true);

        translate([5, 0, 9.1])
            scale([1.0, 0.75, 0.38])
                sphere(d = 5.0);
    }
}

module detent_track() {
    difference() {
        block(26, 18, 8);

        translate([0, 0, 4.8])
            cube([27, 6.8 + fit, 2.6 + fit], center = true);

        translate([0, 0, 6.8])
            cube([27, 2.8 + fit, 3.1 + fit], center = true);

        for (x_position = [-6, 0, 6])
            translate([x_position, 0, 7.4])
                scale([1.0, 0.8, 0.45])
                    sphere(d = 5.5 + fit);
    }
}

module cam_clamp_body() {
    difference() {
        union() {
            block(28, 24, 16);
            translate([0, 8.5, 8])
                cube([28, 7, 16], center = true);
        }

        translate([0, 0, 8])
            round_pin_x(30, 12.4);

        translate([0, -9, 8])
            cube([30, 8.0, 14.5], center = true);

        translate([0, 11.5, 8])
            round_pin_x(31, 3.4);

        translate([0, 6.4, 8])
            cube([8, 8, 10], center = true);
    }
}

module cam_lever_part() {
    difference() {
        union() {
            translate([-5, 0, 2])
                cube([28, 6, 4], center = true);
            translate([8, 0, 2])
                scale([1.35, 1.0, 1.0])
                    cylinder(d = 12, h = 4, center = true);
            translate([-19, 0, 2])
                cylinder(d = 7, h = 4, center = true);
        }

        translate([0, 0, 2])
            cylinder(d = 3.4, h = 4.4, center = true);
    }
}

module cam_pin() {
    union() {
        cylinder(d = 3.0, h = 27);
        cylinder(d = 5.2, h = 1.2);
        translate([0, 0, 25.8])
            cylinder(d = 5.2, h = 1.2);
    }
}

module rack_teeth(length = 24, tooth_count = 8, base_z = 5) {
    tooth_pitch = length / tooth_count;

    for (index = [0 : tooth_count - 1]) {
        translate([
            -length / 2 + index * tooth_pitch + tooth_pitch / 2,
            0,
            base_z
        ])
            prism_x(
                tooth_pitch * 0.86,
                [
                    [-4.4, 0],
                    [4.4, 0],
                    [0, 3.0]
                ]
            );
    }
}

module rack_bar() {
    union() {
        block(28, 12, 5);
        rack_teeth(24, 8, 4.9);
    }
}

module rack_pawl() {
    union() {
        block(24, 16, 6);

        translate([-8, -2.2, 5.9])
            cube([16, 4.4, 1.25]);

        translate([6.8, 0, 6.9])
            prism_x(
                3.0,
                [
                    [-4.0, 0],
                    [4.0, 0],
                    [0, 3.2]
                ]
            );

        translate([8, 0, 4.6])
            cube([4, 9.5, 2.0], center = true);
    }
}

assert(
    known_part(prototype, part),
    str("Unknown prototype/part combination: prototype=", prototype, " part=", part)
);

if (prototype == 1 && part == "dovetail_male") {
    dovetail_male();
} else if (prototype == 1 && part == "dovetail_socket") {
    dovetail_socket();
} else if (prototype == 2 && part == "bayonet_plug") {
    bayonet_plug();
} else if (prototype == 2 && part == "bayonet_socket") {
    bayonet_socket();
} else if (prototype == 3 && part == "snap_hook") {
    snap_hook();
} else if (prototype == 3 && part == "snap_socket") {
    snap_socket();
} else if (prototype == 4 && part == "wedge_left") {
    wedge_receiver(true);
} else if (prototype == 4 && part == "wedge_right") {
    wedge_receiver(false);
} else if (prototype == 4 && part == "wedge_key") {
    wedge_key();
} else if (prototype == 5 && part == "t_slider") {
    t_slider();
} else if (prototype == 5 && part == "t_track") {
    t_track();
} else if (prototype == 6 && part == "split_pin_male") {
    split_pin_male();
} else if (prototype == 6 && part == "split_pin_socket") {
    split_pin_socket();
} else if (prototype == 7 && part == "thread_plug") {
    thread_plug();
} else if (prototype == 7 && part == "thread_socket") {
    thread_socket();
} else if (prototype == 8 && part == "detent_slider") {
    detent_slider();
} else if (prototype == 8 && part == "detent_track") {
    detent_track();
} else if (prototype == 9 && part == "cam_clamp_body") {
    cam_clamp_body();
} else if (prototype == 9 && part == "cam_lever") {
    cam_lever_part();
} else if (prototype == 9 && part == "cam_pin") {
    cam_pin();
} else if (prototype == 10 && part == "rack_bar") {
    rack_bar();
} else if (prototype == 10 && part == "rack_pawl") {
    rack_pawl();
}
