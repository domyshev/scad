// Printed M8-sized fasteners for the 2026-07-12 modular link.
//
// These parts are matched printed hardware. They fit the M8-link clearance
// hole, but are not standard metal M8 thread geometry.

$fn = 96;

use <../../lib/core/threads/threads.scad>

part = "assembly_preview"; // hex_bolt, hex_nut, assembly_preview
preview_fast = $preview;

bolt_outer_d = 8.4;
link_bolt_clearance_d = 8.8;
thread_pitch = 1.5;
thread_size = 1.0;
nut_thread_cut_d = 9.0;
external_thread_leadin = 2;
internal_thread_leadin = 0;
nut_mouth_chamfer_h = 0.35;
nut_mouth_chamfer_extra_d = 1.2;

link_thickness = 6;
tooth_height = 0.7;
tooth_valley_height = 0.1;
assembly_stack_h = 2 * link_thickness + tooth_height + tooth_valley_height;

bolt_head_af = 13.0;
bolt_head_h = 5.5;
bolt_under_head_len = 26.0;
bolt_smooth_len = 13.0;
bolt_thread_len = 13.0;

hex_nut_af = 13.0;
hex_nut_h = 7.0;

fit_overlap = 0.05;
hex_chamfer = 0.45;

assert(
    bolt_outer_d < link_bolt_clearance_d,
    "Printed M8 bolt must clear the M8 modular-link bolt hole"
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
        "M8_FASTENER_PARAMETERS ",
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

module assembly_preview() {
    color("#6B7280")
        hex_bolt();

    translate([28, 0, 0])
        color("#10B981")
            hex_nut();
}

if (part == "hex_bolt") {
    hex_bolt();
} else if (part == "hex_nut") {
    hex_nut();
} else if (part == "assembly_preview") {
    assembly_preview();
} else {
    assert(false, str("Unknown part: ", part));
}
