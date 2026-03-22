include <involute.scad>

// Public module: draw an involute spur gear (ISO).
// pitch_diameter = diameter of pitch circle (mm)
// teeth = number of teeth
// gear_thickness = height of gear (mm)
// pressure_angle = in degrees (default 20)
// involute_facets = segments per tooth flank (0 = use $fn/4)
// bore_diameter = diameter of central cylindrical hole (mm). false, 0 or undef = no bore
// cross_axle = central cross cutout for LEGO-style axle: false/undef = none; true = default LEGO size;
//   number = circumscribed diameter (mm); [diameter, arm_width] = full spec. When set, overrides bore_diameter in center
module drawGear(pitch_diameter, teeth, gear_thickness, pressure_angle = 20, involute_facets = 0, bore_diameter = undef, cross_axle = false) {
    pitch_r = pitch_diameter / 2;
    base_r = pitch_r * cos(pressure_angle);
    module_val = pitch_diameter / teeth;
    addendum = module_val;
    dedendum = 1.25 * module_val;   // includes standard clearance 0.25*module
    outer_r = pitch_r + addendum;
    root_r = pitch_r - dedendum;
    half_thick_angle = (360 / teeth) / 4;
    facets = (involute_facets > 0) ? involute_facets : max(4, $fn / 4);

    use_bore = (bore_diameter != undef && bore_diameter != false && bore_diameter > 0);
    use_cross = (cross_axle != undef && cross_axle != false &&
        (cross_axle == true || (cross_axle > 0) || (is_list(cross_axle) && len(cross_axle) >= 1)));

    cross_d = (cross_axle == true) ? 4.85 : (is_list(cross_axle) ? cross_axle[0] : cross_axle);
    cross_w = (is_list(cross_axle) && len(cross_axle) >= 2) ? cross_axle[1] : 1.9;

    difference() {
        linear_extrude(gear_thickness, center = true)
            _gear_shape_2d(teeth, pitch_r, root_r, base_r, outer_r, half_thick_angle, facets);
        if (use_bore && !use_cross)
            cylinder(d = bore_diameter, h = gear_thickness + 2, center = true);
        if (use_cross)
            linear_extrude(gear_thickness + 2, center = true)
                _cross_2d(cross_d, cross_w);
    }
}