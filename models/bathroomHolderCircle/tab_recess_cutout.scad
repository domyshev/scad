// "Вырез под выступ": symmetric pockets on the outer wall at +Y and −Y (perpendicular to the pin line on ±X).
// Tangent width 12 mm, radial depth 2 mm; axial extent for each pocket is set separately (from z = 0 upward).

base_outer_r = 40 / 2;
tab_recess_width = 12;
tab_recess_depth = 2;
base_height = 6.6;

// Axial height (mm) of each pocket from z = 0; set independently for +Y and −Y sides.
tab_recess_z_plus_y = 6.6 - 3.6;
tab_recess_z_minus_y = 7.6;

// Single pocket: yaw_deg = 0 → +Y rim; yaw_deg = 180 → −Y rim.
module tab_recess_pocket(z_height, yaw_deg) {
    eps = 0.01;
    rotate([0, 0, yaw_deg])
        translate([0, base_outer_r - tab_recess_depth / 2 + eps / 2, z_height / 2])
            cube([tab_recess_width + 2 * eps, tab_recess_depth + 2 * eps, z_height + 2 * eps], center = true);
}

module tab_recess_cutout() {
    tab_recess_pocket(tab_recess_z_plus_y, 0);
    tab_recess_pocket(tab_recess_z_minus_y, 180);
}
