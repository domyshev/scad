use <../../models/iphone_holder/2026-07-11_modular_link_concept.scad>

angle = 45;
probe_clearance = 0.01;

intersection() {
    translate([-20, 0, 0]) modular_link();
    translate([0, 0, 12.8 + probe_clearance])
        rotate([0, 0, angle])
            translate([20, 0, 0])
                rotate([180, 0, 0])
                    modular_link();
}
