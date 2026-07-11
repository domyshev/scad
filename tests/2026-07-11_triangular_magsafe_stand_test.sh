#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_model="$repo_root/models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad"

if [[ ! -f "$source_model" ]]; then
    echo "FAIL: missing triangular MagSafe stand source: $source_model" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

count_ascii_stl_edge_components() {
    python3 - "$1" <<'PY'
import sys

triangles = []
triangle = []

with open(sys.argv[1], encoding="utf-8") as stl_file:
    for line in stl_file:
        fields = line.split()
        if fields[:1] != ["vertex"]:
            continue

        triangle.append(tuple(float(value) for value in fields[1:4]))
        if len(triangle) == 3:
            triangles.append(tuple(triangle))
            triangle = []

parent = list(range(len(triangles)))


def find(item):
    while parent[item] != item:
        parent[item] = parent[parent[item]]
        item = parent[item]
    return item


def union(left, right):
    left_root = find(left)
    right_root = find(right)
    if left_root != right_root:
        parent[right_root] = left_root


edge_owner = {}
edge_incidence = {}
for triangle_index, vertices in enumerate(triangles):
    for start, end in ((0, 1), (1, 2), (2, 0)):
        edge = tuple(sorted((vertices[start], vertices[end])))
        edge_incidence[edge] = edge_incidence.get(edge, 0) + 1
        if edge in edge_owner:
            union(triangle_index, edge_owner[edge])
        else:
            edge_owner[edge] = triangle_index

invalid_edges = [
    edge for edge, incidence in edge_incidence.items() if incidence != 2
]
if invalid_edges:
    raise SystemExit(
        f"STL is not watertight: {len(invalid_edges)} edges have incidence != 2"
    )

print(len({find(index) for index in range(len(triangles))}))
PY
}

ascii_stl_volume() {
    python3 - "$1" <<'PY'
import sys

volume = 0.0
triangle = []


def cross(left, right):
    return (
        left[1] * right[2] - left[2] * right[1],
        left[2] * right[0] - left[0] * right[2],
        left[0] * right[1] - left[1] * right[0],
    )


def dot(left, right):
    return sum(a * b for a, b in zip(left, right))


with open(sys.argv[1], encoding="utf-8") as stl_file:
    for line in stl_file:
        fields = line.split()
        if fields[:1] != ["vertex"]:
            continue

        triangle.append(tuple(float(value) for value in fields[1:4]))
        if len(triangle) == 3:
            volume += dot(
                triangle[0],
                cross(triangle[1], triangle[2]),
            ) / 6
            triangle = []

print(f"{volume:.6f}")
PY
}

render_scene() {
    local scene_name="$1"
    local output_stl="$tmp_dir/${scene_name}.stl"
    local summary_json="$tmp_dir/${scene_name}.json"
    local render_log="$tmp_dir/${scene_name}.log"

    if ! openscad \
        --backend CGAL \
        --export-format asciistl \
        --hardwarnings \
        --summary all \
        --summary-file "$summary_json" \
        -o "$output_stl" \
        -D "scene=\"$scene_name\"" \
        -D 'show_hardware=true' \
        "$source_model" >"$render_log" 2>&1; then
        cat "$render_log" >&2
        exit 1
    fi

    if [[ ! -s "$output_stl" ]]; then
        echo "FAIL: scene $scene_name produced no STL geometry" >&2
        exit 1
    fi

    jq -e '.geometry.dimensions == 3' "$summary_json" >/dev/null
}

render_scene "frame_pair"
render_scene "joint_spacer"
render_scene "frame_envelope"
render_scene "ballast_void"
render_scene "ballast_body"
render_scene "ballast_lid"

jq -e '
  (.geometry.bounding_box.size[0] - 100 | fabs) < 0.5 and
  (.geometry.bounding_box.size[1] - 90 | fabs) < 0.5 and
  (.geometry.bounding_box.size[2] - 89.282 | fabs) < 0.5
' "$tmp_dir/frame_envelope.json" >/dev/null

jq -e '
  (.geometry.bounding_box.min[1] + 45 | fabs) < 0.05 and
  (.geometry.bounding_box.max[1] - 45 | fabs) < 0.05
' "$tmp_dir/frame_envelope.json" >/dev/null

jq -e '
  (.geometry.bounding_box.size[1] - 64.4 | fabs) < 0.05
' "$tmp_dir/joint_spacer.json" >/dev/null

spacer_components="$(
    count_ascii_stl_edge_components "$tmp_dir/joint_spacer.stl"
)"
if [[ "$spacer_components" != "1" ]]; then
    echo "FAIL: joint spacer exports as $spacer_components disconnected STL shells" >&2
    exit 1
fi

fillable_volume="$(ascii_stl_volume "$tmp_dir/ballast_void.stl")"
jq -e \
    --argjson fillable_volume "$fillable_volume" \
    '.geometry.simple == true and $fillable_volume >= 130000' \
    "$tmp_dir/ballast_void.json" >/dev/null

void_components="$(
    count_ascii_stl_edge_components "$tmp_dir/ballast_void.stl"
)"
if [[ "$void_components" != "1" ]]; then
    echo "FAIL: ballast_void contains $void_components disconnected fill regions" >&2
    exit 1
fi

for ballast_part in ballast_body ballast_lid; do
    jq -e '.geometry.simple == true' \
        "$tmp_dir/${ballast_part}.json" >/dev/null

    ballast_part_volume="$(
        ascii_stl_volume "$tmp_dir/${ballast_part}.stl"
    )"
    awk -v volume="$ballast_part_volume" \
        'BEGIN { exit !(volume > 0) }'

    ballast_components="$(
        count_ascii_stl_edge_components "$tmp_dir/${ballast_part}.stl"
    )"
    if [[ "$ballast_components" != "1" ]]; then
        echo "FAIL: $ballast_part exports as $ballast_components disconnected STL shells" >&2
        exit 1
    fi
done

jq -e '
  (.geometry.bounding_box.size[1] - 64.4 | fabs) < 0.05
' "$tmp_dir/ballast_body.json" >/dev/null

ballast_overlap_stl="$tmp_dir/frame_ballast_overlap.stl"
ballast_overlap_log="$tmp_dir/frame_ballast_overlap.log"
if openscad \
    --backend CGAL \
    --hardwarnings \
    -o "$ballast_overlap_stl" \
    -D 'scene="frame_ballast_overlap"' \
    -D 'ballast_collision_probe=0.05' \
    -D 'show_hardware=false' \
    "$source_model" >"$ballast_overlap_log" 2>&1; then
    ballast_overlap_exit=0
else
    ballast_overlap_exit=$?
fi

if [[ -s "$ballast_overlap_stl" ]]; then
    echo "FAIL: frame and ballast intersect within the 0.05 mm contact probe" >&2
    exit 1
fi

if [[ "$ballast_overlap_exit" != "1" ]]; then
    echo "FAIL: unexpected frame/ballast overlap-probe result" >&2
    cat "$ballast_overlap_log" >&2
    exit 1
fi

grep -q 'Current top level object is empty' "$ballast_overlap_log"

cat >"$tmp_dir/ballast_lid_fit_overlap.scad" <<SCAD
use <${source_model}>

\$fn = 72;

intersection() {
    ballast_cassette_body();
    ballast_cassette_lid();
}
SCAD

lid_fit_overlap_stl="$tmp_dir/ballast_lid_fit_overlap.stl"
lid_fit_overlap_log="$tmp_dir/ballast_lid_fit_overlap.log"
if openscad \
    --backend CGAL \
    --hardwarnings \
    -o "$lid_fit_overlap_stl" \
    "$tmp_dir/ballast_lid_fit_overlap.scad" \
    >"$lid_fit_overlap_log" 2>&1; then
    lid_fit_overlap_exit=0
else
    lid_fit_overlap_exit=$?
fi

if [[ -s "$lid_fit_overlap_stl" ]]; then
    echo "FAIL: closed ballast lid intersects its body or rails" >&2
    exit 1
fi

if [[ "$lid_fit_overlap_exit" != "1" ]]; then
    echo "FAIL: unexpected ballast lid-fit overlap result" >&2
    cat "$lid_fit_overlap_log" >&2
    exit 1
fi

grep -q 'Current top level object is empty' "$lid_fit_overlap_log"

cat >"$tmp_dir/spacer_bore_clearance.scad" <<SCAD
use <${source_model}>

\$fn = 72;

intersection() {
    joint_spacer();

    union() {
        rotate([90, 0, 0])
            cylinder(d = 4.75, h = 66.4, center = true);

        translate([0, 0, 3.1])
            cube([0.1, 66.4, 0.1], center = true);
    }
}
SCAD

clearance_stl="$tmp_dir/spacer_bore_clearance.stl"
clearance_log="$tmp_dir/spacer_bore_clearance.log"
if openscad \
    --backend CGAL \
    --hardwarnings \
    -o "$clearance_stl" \
    "$tmp_dir/spacer_bore_clearance.scad" >"$clearance_log" 2>&1; then
    echo "FAIL: 4.75 mm teardrop clearance probe intersects the spacer" >&2
    exit 1
else
    clearance_exit=$?
fi

if [[ "$clearance_exit" != "1" || -s "$clearance_stl" ]]; then
    echo "FAIL: unexpected spacer clearance-probe result" >&2
    cat "$clearance_log" >&2
    exit 1
fi

grep -q 'Current top level object is empty' "$clearance_log"

cat >"$tmp_dir/spacer_bore_limit.scad" <<SCAD
use <${source_model}>

\$fn = 72;

intersection() {
    joint_spacer();

    rotate([90, 0, 0])
        cylinder(d = 4.90, h = 66.4, center = true);
}
SCAD

limit_stl="$tmp_dir/spacer_bore_limit.stl"
limit_log="$tmp_dir/spacer_bore_limit.log"
if ! openscad \
    --backend CGAL \
    --hardwarnings \
    -o "$limit_stl" \
    "$tmp_dir/spacer_bore_limit.scad" >"$limit_log" 2>&1; then
    cat "$limit_log" >&2
    exit 1
fi

if [[ ! -s "$limit_stl" ]]; then
    echo "FAIL: 4.90 mm bore-limit probe found no spacer wall" >&2
    exit 1
fi

printf \
    'PASS: triangular MagSafe stand frame, spacer, and ballast geometry are valid (fillable volume %.3f mm3)\n' \
    "$fillable_volume"
