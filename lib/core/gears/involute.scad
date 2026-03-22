// Involute spur gear library (ISO)
// Use: include <drawGear.scad>
// Public: module drawGear(pitch_diameter, teeth, gear_thickness, pressure_angle=20, involute_facets=0)

// Involute angle (degrees) at given radius
function involute_intersect_angle(base_r, r) = sqrt(pow(r / base_r, 2) - 1) * 180 / PI;

// Involute point [x,y] for base radius and angle in degrees
function involute(base_r, angle_deg) = [
    base_r * (cos(angle_deg) + (angle_deg * PI / 180) * sin(angle_deg)),
    base_r * (sin(angle_deg) - (angle_deg * PI / 180) * cos(angle_deg))
];

function _rotate_pt(angle_deg, p) = [
    cos(angle_deg) * p[0] + sin(angle_deg) * p[1],
    cos(angle_deg) * p[1] - sin(angle_deg) * p[0]
];

function _mirror_pt(p) = [p[0], -p[1]];

module _involute_tooth_2d(pitch_r, root_r, base_r, outer_r, half_thick_angle, facets) {
    min_r = max(base_r, root_r);
    pitch_pt = involute(base_r, involute_intersect_angle(base_r, pitch_r));
    pitch_angle = atan2(pitch_pt[1], pitch_pt[0]);
    centre_angle = pitch_angle + half_thick_angle;
    start_angle = involute_intersect_angle(base_r, min_r);
    stop_angle = involute_intersect_angle(base_r, outer_r);

    for (i = [1 : facets]) {
        t1 = (i - 1) / facets;
        t2 = i / facets;
        pt1 = involute(base_r, start_angle + (stop_angle - start_angle) * t1);
        pt2 = involute(base_r, start_angle + (stop_angle - start_angle) * t2);
        s1a = _rotate_pt(centre_angle, pt1);
        s1b = _rotate_pt(centre_angle, pt2);
        s2a = _mirror_pt(s1a);
        s2b = _mirror_pt(s1b);
        polygon(points = [[0, 0], s1a, s1b, s2b, s2a], paths = [[0, 1, 2, 3, 4, 0]]);
    }
}

module _gear_shape_2d(teeth, pitch_r, root_r, base_r, outer_r, half_thick_angle, facets) {
    union() {
        rotate(half_thick_angle) circle(r = root_r, $fn = teeth * 2);
        for (i = [1 : teeth]) {
            rotate([0, 0, i * 360 / teeth])
                _involute_tooth_2d(pitch_r, root_r, base_r, outer_r, half_thick_angle, facets);
        }
    }
}

// 2D cross (plus) for LEGO-style axle; circumscribed diameter and arm width in mm
module _cross_2d(cross_diameter, arm_width) {
    half_len = cross_diameter / 2;
    half_w = arm_width / 2;
    union() {
        polygon(points = [[-half_w, -half_len], [half_w, -half_len], [half_w, half_len], [-half_w, half_len]]);
        polygon(points = [[-half_len, -half_w], [half_len, -half_w], [half_len, half_w], [-half_len, half_w]]);
    }
}
