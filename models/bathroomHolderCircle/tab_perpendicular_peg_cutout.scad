// Radial cylinder through tab-recess rim (axis ⊥ XZ back wall of tab_recess_pocket).
// Geometry parameters match the tab pocket on the outer wall (see tab_recess_cutout.scad).

module tab_perpendicular_peg_cutout() {
    base_outer_r = 40 / 2;
    tab_recess_depth = 2;
    tab_perpendicular_peg_d = 4;
    tab_perpendicular_peg_z = 2 + 1.6;
    tab_perpendicular_peg_length = 18;
    y_offset = 10;

    y_center = -1 * (base_outer_r - tab_recess_depth / 2);
    translate([0, y_center + y_offset, tab_perpendicular_peg_z])
        rotate([90, 0, 0])
            cylinder(h = tab_perpendicular_peg_length, d = tab_perpendicular_peg_d, center = true);
}
