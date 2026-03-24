// Vertical through-plate holes for LEGO-style pins along the outer boundary of the side frame hull
// (three disks: main hub, wheel arm, lower gear pod). Spacing along arc = pitch (8 mm). Skips
// positions too close to existing axle holes (legoAxisHole).

// Outward boundary point for the convex hull of three disks: support in direction u = (cos t, sin t).
function _hull_support_disk_(t, c, r) = c + r * [cos(t), sin(t)];

function _hull_support_point_(t, c1, r1, c2, r2, c3, r3) =
    let(u = [cos(t), sin(t)])
    let(s1 = c1[0] * u[0] + c1[1] * u[1] + r1)
    let(s2 = c2[0] * u[0] + c2[1] * u[1] + r2)
    let(s3 = c3[0] * u[0] + c3[1] * u[1] + r3)
    s1 >= s2 && s1 >= s3 ? _hull_support_disk_(t, c1, r1)
    : s2 >= s3 ? _hull_support_disk_(t, c2, r2)
    : _hull_support_disk_(t, c3, r3);

function _polyline_len_(pts, i = 0) =
    i >= len(pts) - 1 ? 0
    : norm(pts[i + 1] - pts[i]) + _polyline_len_(pts, i + 1);

// Walk open polyline pts[j..] until arc length s_rem is consumed; return interpolated point.
function _point_at_arc_(pts, j, s_rem) =
    j >= len(pts) - 1 ? pts[len(pts) - 1]
    : let(d = norm(pts[j + 1] - pts[j]))
        s_rem < d ? pts[j] + (s_rem / d) * (pts[j + 1] - pts[j])
        : _point_at_arc_(pts, j + 1, s_rem - d);

// Minimum distance from p to any axle center in XY (axle_holes = list of [x,y]).
function _min_dist_to_axles_(p, axle_holes, i = 0) =
    i >= len(axle_holes) ? 1e9
    : min(norm(p - axle_holes[i]), _min_dist_to_axles_(p, axle_holes, i + 1));

// Frame hull disk centers / radii (must match sideFrame hull cylinders).
function _frame_disk_centers_radii_() =
    let(c1 = [0, 0])
    let(r1 = 15)
    let(c2 = [-wheel_dist, -pitch * 3])
    let(r2 = 8)
    let(c3 = fin_gear_xy)
    let(r3 = 8)
    [c1, r1, c2, r2, c3, r3];

// Closed boundary polyline (fine angular step).
function _frame_boundary_polyline_(step = 0.25) =
    let(dr = _frame_disk_centers_radii_())
    let(c1 = dr[0], r1 = dr[1], c2 = dr[2], r2 = dr[3], c3 = dr[4], r3 = dr[5])
    let(raw = [for (a = [0 : step : 359.99]) _hull_support_point_(a, c1, r1, c2, r2, c3, r3)])
    concat(raw, [raw[0]]);

// All axle hole centers in XY (symmetric left/right + motor + center).
function _side_frame_axle_centers_() = concat(
        [[0, 0]],
        [[pitch, 0], [-pitch, 0], [0, pitch], [0, -pitch]],
        [for (s = [-1, 1]) [s * mid_gear_xy[0], mid_gear_xy[1]]],
        [for (s = [-1, 1]) [s * fin_gear_xy[0], fin_gear_xy[1]]]
    );

// Bottom opening cutter in sideFrame (same XY as the large subtracting cylinder).
function _outside_bottom_frame_cutter_(p) =
    let(c = [0, -182])
    let(r = 330 / 2)
    norm(p - c) >= r;

// Skip pin holes whose center is closer than pitch (8 mm) to any axle center — LEGO grid spacing.
// Also skip centers that lie in material removed by the bottom opening cylinder.
function perimeter_pin_hole_positions(angular_step = 0.25) =
    let(pts = _frame_boundary_polyline_(angular_step))
    let(L = _polyline_len_(pts))
    let(n = max(0, floor(L / pitch)))
    let(axles = _side_frame_axle_centers_())
    [
        for (k = [0 : n - 1])
            let(s = k * pitch + pitch / 2)
            let(p = _point_at_arc_(pts, 0, s))
            if (_min_dist_to_axles_(p, axles) >= pitch && _outside_bottom_frame_cutter_(p))
                p
    ];

module legoVerticalPinHole(h = undef, d = undef) {
    _h = is_undef(h) ? thickness + 2 : h;
    _d = is_undef(d) ? hole_d : d;
    cylinder(d = _d, h = _h, center = true);
}
