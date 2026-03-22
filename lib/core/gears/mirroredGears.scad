// Two identical gears on ±X from the Y axis, opposite Z rotation for meshing (uses global thickness).
// Odd tooth count has no 180° rotational symmetry on the tooth lattice, so ±phase alone looks
// asymmetric left vs right; add 180° on the s = -1 side (negative X) to mirror the pattern visually.
module mirroredGears(teeth, phase_z, gx, gy, gear_color) {
    z = max(8, round(teeth));
    odd_z_mirror = (z % 2 == 1) ? 1 : 0;
    color(gear_color)
    for (s = [1, -1]) {
        extra_z = odd_z_mirror * ((s == -1) ? 180 : 0);
        translate([s * gx, gy, thickness])
            rotate([0, 0, s * phase_z + extra_z])
                drawGearByTeeth(teeth);
    }
}