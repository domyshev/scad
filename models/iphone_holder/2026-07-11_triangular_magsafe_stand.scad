// Two-frame triangular skeleton for the modular-link MagSafe stand.
//
// Each 80 mm side uses two 40 mm modular links. Adjacent segments alternate
// face-up / face-down so their repaired radial serrations physically mate.

use <2026-07-11_modular_link_concept.scad>

$fn = 72;

scene = "frame_pair"; // frame_pair, joint_spacer, frame_envelope
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

if (scene == "frame_pair") {
    frame_pair();
} else if (scene == "joint_spacer") {
    joint_spacer();
} else if (scene == "frame_envelope") {
    frame_pair();
} else {
    assert(false, str("Unknown scene: ", scene));
}
