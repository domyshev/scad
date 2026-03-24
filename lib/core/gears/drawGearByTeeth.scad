// Integer tooth count; pitch diameter = teeth * gear_module (same module everywhere so gears mesh)
// Central opening: cross_axle [gear_center_cross_d, gear_center_cross_arm_w] from caller (e.g. funnyAtv.scad)
module drawGearByTeeth(teeth) {
    z = max(8, round(teeth));
    drawGear(
            z * gear_module,
            z,
            thickness,
            gear_pressure_angle,
            involute_facets = 0,
            bore_diameter = false,
            cross_axle = [gear_center_cross_d, gear_center_cross_arm_w]
        );
}