// Modular iPhone-stand link concept.
//
// The drawing demonstrates one repeatable flat link with one-sided radial face
// serrations. Identical links alternate face-up / face-down. The serration
// flanks transmit joint torque while M4 supplies the axial seating preload.

$fn = 72;

scene = "presentation"; // single_link, exploded_joint, assembled_joint, joint_overlap, presentation
show_hardware = true;
joint_angle = 45;
supported_joint_angle_min = 0;
supported_joint_angle_max = 150;

// The link is dimensioned by joint-center pitch, not by total end-to-end size.
link_pitch = 40;
joint_d = 20;
link_thickness = 6;

bolt_clearance_d = 4.6;

tooth_count = 24;
tooth_height = 0.7;
tooth_valley_height = 0.1;
tooth_embed = 0.2;
tooth_inner_d = 10;
tooth_outer_d = 18;

// Used only by the diagnostic intersection scene. It removes zero-volume
// contact skins while preserving any real tooth-to-tooth interference.
overlap_probe_clearance = 0.01;

tooth_pitch_angle = 360 / tooth_count;
serration_station_count = 2 * tooth_count;
serration_step_angle = 360 / serration_station_count;
assembly_stack_h =
    2 * link_thickness + tooth_height + tooth_valley_height;
exploded_gap = 10;

m4_bolt_d = 4;
m4_bolt_head_d = 8;
m4_bolt_head_h = 2.8;
m4_washer_d = 10;
m4_washer_h = 0.8;
m4_nut_flat = 7;
m4_nut_h = 3.2;

lower_color = "#F59E0B";
upper_color = "#3B82F6";
single_color = "#10B981";
hardware_color = "#6B7280";
label_color = "#374151";

function modular_link_pitch() = link_pitch;
function modular_joint_d() = joint_d;
function modular_link_body_h() = link_thickness;
function modular_link_stack_h() = assembly_stack_h;
function modular_bolt_clearance_d() = bolt_clearance_d;

function polar3(radius, angle, z_position) = [
    radius * cos(angle),
    radius * sin(angle),
    z_position
];

function sector_midpoint(radius, station_index, z_position) =
    polar3(
        radius,
        (station_index + 0.5) * serration_step_angle,
        z_position
    );

function serration_height(station_index) =
    station_index % 2 == 0 ? tooth_height : tooth_valley_height;

function joint_angle_is_indexed(angle) =
    abs(angle / tooth_pitch_angle - round(angle / tooth_pitch_angle)) < 0.0001;

module capsule_2d() {
    hull() {
        translate([-link_pitch / 2, 0])
            circle(d = joint_d);

        translate([link_pitch / 2, 0])
            circle(d = joint_d);
    }
}

module serration_ring() {
    inner_r = tooth_inner_d / 2;
    outer_r = tooth_outer_d / 2;
    ring_points = [
        for (station_index = [0 : serration_station_count - 1])
            let(
                next_index =
                    (station_index + 1) % serration_station_count,
                top_mid_z =
                    (
                        serration_height(station_index) +
                            serration_height(next_index)
                    ) / 2,
                side_mid_z = (-tooth_embed + top_mid_z) / 2
            )
            each [
                polar3(
                    inner_r,
                    station_index * serration_step_angle,
                    -tooth_embed
                ),
                polar3(
                    outer_r,
                    station_index * serration_step_angle,
                    -tooth_embed
                ),
                polar3(
                    inner_r,
                    station_index * serration_step_angle,
                    serration_height(station_index)
                ),
                polar3(
                    outer_r,
                    station_index * serration_step_angle,
                    serration_height(station_index)
                ),
                sector_midpoint(
                    (inner_r + outer_r) / 2,
                    station_index,
                    top_mid_z
                ),
                sector_midpoint(
                    (inner_r + outer_r) / 2,
                    station_index,
                    -tooth_embed
                ),
                sector_midpoint(outer_r, station_index, side_mid_z),
                sector_midpoint(inner_r, station_index, side_mid_z)
            ]
    ];
    ring_faces = [
        for (station_index = [0 : serration_station_count - 1])
            let(
                next_index =
                    (station_index + 1) % serration_station_count,
                bottom_inner = 8 * station_index,
                bottom_outer = bottom_inner + 1,
                top_inner = bottom_inner + 2,
                top_outer = bottom_inner + 3,
                top_midpoint = bottom_inner + 4,
                bottom_midpoint = bottom_inner + 5,
                outer_midpoint = bottom_inner + 6,
                inner_midpoint = bottom_inner + 7,
                next_bottom_inner = 8 * next_index,
                next_bottom_outer = next_bottom_inner + 1,
                next_top_inner = next_bottom_inner + 2,
                next_top_outer = next_bottom_inner + 3
            )
                each [
                    [top_inner, top_outer, top_midpoint],
                    [top_outer, next_top_outer, top_midpoint],
                    [next_top_outer, next_top_inner, top_midpoint],
                    [next_top_inner, top_inner, top_midpoint],
                    [bottom_inner, next_bottom_inner, bottom_midpoint],
                    [next_bottom_inner, next_bottom_outer, bottom_midpoint],
                    [next_bottom_outer, bottom_outer, bottom_midpoint],
                    [bottom_outer, bottom_inner, bottom_midpoint],
                    [bottom_outer, next_bottom_outer, outer_midpoint],
                    [next_bottom_outer, next_top_outer, outer_midpoint],
                    [next_top_outer, top_outer, outer_midpoint],
                    [top_outer, bottom_outer, outer_midpoint],
                    [bottom_inner, top_inner, inner_midpoint],
                    [top_inner, next_top_inner, inner_midpoint],
                    [next_top_inner, next_bottom_inner, inner_midpoint],
                    [next_bottom_inner, bottom_inner, inner_midpoint]
                ]
    ];

    polyhedron(
        points = ring_points,
        faces = ring_faces,
        convexity = 4
    );
}

module face_serration(position, phase = 0) {
    // The root is embedded into the body so every tooth belongs to the same
    // watertight shell after STL export.
    translate([position[0], position[1], link_thickness])
        rotate([0, 0, phase])
            serration_ring();
}

module joint_hole(position) {
    translate([
        position[0],
        position[1],
        -0.1
    ])
        cylinder(
            d = bolt_clearance_d,
            h = link_thickness + tooth_height + 0.2
        );
}

module modular_link() {
    left_joint = [-link_pitch / 2, 0];
    right_joint = [link_pitch / 2, 0];

    difference() {
        union() {
            linear_extrude(height = link_thickness)
                capsule_2d();

            // The half-pitch phase difference lets identical links mesh in
            // 15-degree steps through the supported 0-to-150-degree range.
            face_serration(left_joint, tooth_pitch_angle / 2);
            face_serration(right_joint, 0);
        }

        joint_hole(left_joint);
        joint_hole(right_joint);
    }
}

module lower_link_at_joint() {
    translate([-link_pitch / 2, 0, 0])
        modular_link();
}

module upper_link_at_joint(
    angle = joint_angle,
    separation = 0,
    validate_angle = true
) {
    assert(
        !validate_angle ||
            (
                angle >= supported_joint_angle_min &&
                    angle <= supported_joint_angle_max
            ),
        str(
            "Supported joint-angle range is ",
            supported_joint_angle_min,
            " to ",
            supported_joint_angle_max,
            " degrees"
        )
    );

    assert(
        !validate_angle || joint_angle_is_indexed(angle),
        str(
            "Joint angle must use ",
            tooth_pitch_angle,
            "-degree indexing"
        )
    );

    translate([0, 0, assembly_stack_h + separation])
        rotate([0, 0, angle])
            translate([link_pitch / 2, 0, 0])
                rotate([180, 0, 0])
                    modular_link();
}

module physical_link_pair(angle = joint_angle, separation = 0) {
    lower_link_at_joint();
    upper_link_at_joint(
        angle = angle,
        separation = separation,
        validate_angle = false
    );
}

module m4_bolt() {
    bolt_bottom = -m4_washer_h - m4_bolt_head_h;
    bolt_top = assembly_stack_h + m4_washer_h + m4_nut_h;

    union() {
        translate([0, 0, bolt_bottom])
            cylinder(d = m4_bolt_head_d, h = m4_bolt_head_h);

        translate([0, 0, bolt_bottom])
            cylinder(d = m4_bolt_d, h = bolt_top - bolt_bottom);
    }
}

module m4_washer_at(z_position) {
    translate([0, 0, z_position])
        difference() {
            cylinder(d = m4_washer_d, h = m4_washer_h);
            translate([0, 0, -0.1])
                cylinder(d = bolt_clearance_d, h = m4_washer_h + 0.2);
        }
}

module m4_nut_at(z_position) {
    nut_vertex_d = m4_nut_flat / cos(30);

    translate([0, 0, z_position])
        difference() {
            rotate([0, 0, 30])
                cylinder(d = nut_vertex_d, h = m4_nut_h, $fn = 6);
            translate([0, 0, -0.1])
                cylinder(d = m4_bolt_d, h = m4_nut_h + 0.2);
        }
}

module m4_hardware(top_offset = 0) {
    m4_bolt();
    m4_washer_at(-m4_washer_h);
    m4_washer_at(assembly_stack_h + top_offset);
    m4_nut_at(assembly_stack_h + top_offset + m4_washer_h);
}

module assembled_joint() {
    color(lower_color)
        lower_link_at_joint();

    color(upper_color)
        upper_link_at_joint();

    if (show_hardware)
        color(hardware_color)
            m4_hardware();
}

module exploded_joint() {
    color(lower_color)
        lower_link_at_joint();

    color(upper_color)
        upper_link_at_joint(separation = exploded_gap);

    if (show_hardware)
        color(hardware_color)
            m4_hardware(top_offset = exploded_gap);
}

module joint_overlap() {
    intersection() {
        lower_link_at_joint();
        upper_link_at_joint(
            separation = overlap_probe_clearance,
            validate_angle = false
        );
    }
}

module drawing_label(label_text, label_size = 6) {
    color(label_color)
        linear_extrude(height = 0.6)
            text(
                label_text,
                size = label_size,
                halign = "center",
                valign = "center"
            );
}

module presentation() {
    translate([-70, 45, 0]) {
        color(single_color)
            modular_link();

        translate([0, -27, 0])
            drawing_label("1  ОДНО ЗВЕНО");

        translate([0, -35, 0])
            drawing_label(
                str(
                    link_pitch + joint_d,
                    " x ",
                    joint_d,
                    " MM | КОРПУС ",
                    link_thickness,
                    " MM"
                ),
                4
            );

        translate([0, -42, 0])
            drawing_label(
                str(
                    "ЗУБ ",
                    tooth_height,
                    " MM | ТОРЦЕВОЙ ПРОФИЛЬ | M4"
                ),
                3.8
            );
    }

    translate([55, 45, 0]) {
        exploded_joint();

        translate([-15, -34, 0])
            drawing_label("2  РАЗНЕСЕННЫЙ УЗЕЛ");

        translate([-15, -42, 0])
            drawing_label(
                str(
                    "M4 | ",
                    tooth_count,
                    " ЗУБА | ШАГ ",
                    tooth_pitch_angle
                ),
                4
            );
    }

    translate([0, -55, 0]) {
        assembled_joint();

        translate([-5, -34, 0])
            drawing_label(
                str("3  СОБРАНО ", joint_angle, " ГРАД")
            );

        translate([-5, -42, 0])
            drawing_label(
                str(
                    "РАБОЧИЙ ДИАПАЗОН ",
                    supported_joint_angle_min,
                    "...",
                    supported_joint_angle_max,
                    " | ШАГ ",
                    tooth_pitch_angle
                ),
                4
            );
    }
}

if (scene == "single_link") {
    modular_link();
} else if (scene == "exploded_joint") {
    exploded_joint();
} else if (scene == "assembled_joint") {
    assembled_joint();
} else if (scene == "joint_overlap") {
    joint_overlap();
} else if (scene == "presentation") {
    presentation();
} else {
    assert(false, str("Unknown scene: ", scene));
}
