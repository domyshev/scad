// Integer tooth count; pitch diameter = teeth * gear_module (same module everywhere so gears mesh)
module drawGearByTeeth(teeth) {
    z = max(8, round(teeth));
    drawGear(z * gear_module, z, thickness, gear_pressure_angle, involute_facets = 0, bore_diameter = false, cross_axle = true);
}