// Printed fasteners for the 2026-07-11 modular iPhone-stand link.
//
// These parts use a matched printed thread. They are not standard M4
// hardware; the larger thread clearance is intentional for FDM/PETG.

$fn = 72;

use <../../lib/core/threads/threads.scad>

part = "assembly_preview"; // hex_bolt, hex_nut, wing_nut, assembly_preview
preview_fast = $preview;

bolt_outer_d = 4.2;
link_bolt_clearance_d = 4.6;
thread_pitch = 1.0;
thread_size = 0.65;
nut_thread_cut_d = 4.65;
external_thread_leadin = 2;
internal_thread_leadin = 0;
nut_mouth_chamfer_h = 0.20;
nut_mouth_chamfer_extra_d = 0.8;

link_thickness = 6;
tooth_height = 0.7;
tooth_valley_height = 0.1;
assembly_stack_h = 2 * link_thickness + tooth_height + tooth_valley_height;

bolt_head_af = 8.0;
bolt_head_h = 3.6;
bolt_under_head_len = 19.0;
bolt_smooth_len = 12.0;
bolt_thread_len = 7.0;

hex_nut_af = 8.0;
hex_nut_h = 4.5;

wing_nut_af = 8.0;
wing_nut_h = 4.8;
wing_span = 28.0;
wing_max_w = 10.0;
wing_root_d = 7.0;

fit_overlap = 0.05;
hex_chamfer = 0.28;

assert(
    bolt_outer_d < link_bolt_clearance_d,
    "Printed bolt must clear the modular-link bolt hole"
);
assert(
    abs(bolt_smooth_len + bolt_thread_len - bolt_under_head_len) < 0.001,
    "Bolt smooth and threaded lengths must equal under-head length"
);
assert(
    bolt_under_head_len > assembly_stack_h + hex_nut_h,
    "Bolt must protrude beyond a two-link stack and hex nut"
);

echo(
    str(
        "FASTENER_PARAMETERS ",
        "bolt_outer_d=", bolt_outer_d,
        " thread_pitch=", thread_pitch,
        " thread_size=", thread_size,
        " nut_thread_cut_d=", nut_thread_cut_d,
        " link_bolt_clearance_d=", link_bolt_clearance_d,
        " assembly_stack_h=", assembly_stack_h
    )
);

function hex_vertex_d(across_flats) = across_flats / cos(30);

module hex_prism(across_flats, height) {
    cylinder(d = hex_vertex_d(across_flats), h = height, $fn = 6);
}

module chamfered_hex_prism(across_flats, height, chamfer = hex_chamfer) {
    effective_chamfer = min(chamfer, height / 3);
    inset_af = max(across_flats - 2 * effective_chamfer, 0.1);
    slice_h = 0.01;

    hull() {
        translate([0, 0, 0])
            hex_prism(inset_af, slice_h);
        translate([0, 0, effective_chamfer])
            hex_prism(across_flats, slice_h);
    }

    translate([0, 0, effective_chamfer - fit_overlap])
        hex_prism(
            across_flats,
            height - 2 * effective_chamfer + 2 * fit_overlap
        );

    hull() {
        translate([0, 0, height - effective_chamfer])
            hex_prism(across_flats, slice_h);
        translate([0, 0, height - slice_h])
            hex_prism(inset_af, slice_h);
    }
}

module printed_external_thread(length) {
    metric_thread(
        diameter = bolt_outer_d,
        pitch = thread_pitch,
        length = length,
        internal = false,
        thread_size = thread_size,
        leadin = external_thread_leadin,
        test = preview_fast
    );
}

module printed_internal_thread_cut(length) {
    metric_thread(
        diameter = nut_thread_cut_d,
        pitch = thread_pitch,
        length = length,
        internal = true,
        thread_size = thread_size,
        leadin = internal_thread_leadin,
        test = preview_fast
    );
}

module hex_bolt() {
    union() {
        chamfered_hex_prism(bolt_head_af, bolt_head_h);

        translate([0, 0, bolt_head_h - fit_overlap])
            cylinder(
                d = bolt_outer_d,
                h = bolt_smooth_len + 2 * fit_overlap
            );

        translate([
            0,
            0,
            bolt_head_h + bolt_smooth_len - fit_overlap
        ])
            printed_external_thread(bolt_thread_len + fit_overlap);
    }
}

module nut_thread_cut(height) {
    union() {
        translate([0, 0, -fit_overlap])
            printed_internal_thread_cut(height + 2 * fit_overlap);

        translate([0, 0, -fit_overlap])
            cylinder(
                d1 = nut_thread_cut_d + nut_mouth_chamfer_extra_d,
                d2 = nut_thread_cut_d,
                h = nut_mouth_chamfer_h + fit_overlap
            );

        translate([0, 0, height - nut_mouth_chamfer_h])
            cylinder(
                d1 = nut_thread_cut_d,
                d2 = nut_thread_cut_d + nut_mouth_chamfer_extra_d,
                h = nut_mouth_chamfer_h + fit_overlap
            );
    }
}

module hex_nut() {
    difference() {
        chamfered_hex_prism(hex_nut_af, hex_nut_h);
        nut_thread_cut(hex_nut_h);
    }
}

module wing_lobes_2d() {
    for (side = [-1, 1]) {
        hull() {
            translate([
                side * (hex_vertex_d(wing_nut_af) / 2 - 0.25),
                0
            ])
                circle(d = wing_root_d);

            translate([
                side * (wing_span / 2 - wing_max_w / 2),
                0
            ])
                circle(d = wing_max_w);
        }
    }
}

module wing_nut_body() {
    union() {
        linear_extrude(height = wing_nut_h)
            wing_lobes_2d();

        chamfered_hex_prism(wing_nut_af, wing_nut_h);
    }
}

module wing_nut() {
    difference() {
        wing_nut_body();
        nut_thread_cut(wing_nut_h);
    }
}

module assembly_preview() {
    color("#6B7280")
        hex_bolt();

    translate([14, 0, 0])
        color("#10B981")
            hex_nut();

    translate([36, 0, 0])
        color("#F59E0B")
            wing_nut();
}

if (part == "hex_bolt") {
    hex_bolt();
} else if (part == "hex_nut") {
    hex_nut();
} else if (part == "wing_nut") {
    wing_nut();
} else if (part == "assembly_preview") {
    assembly_preview();
} else {
    assert(false, str("Unknown part: ", part));
}
