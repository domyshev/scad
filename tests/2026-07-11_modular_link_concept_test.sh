#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_model="$repo_root/models/iphone_holder/2026-07-11_modular_link_concept.scad"
physical_overlap_fixture="$repo_root/tests/fixtures/2026-07-11_physical_link_overlap.scad"
artifact_dir="$repo_root/stl/2026-07-11"

if [[ ! -f "$source_model" ]]; then
    echo "FAIL: missing modular-link concept source: $source_model" >&2
    exit 1
fi

if [[ ! -f "$physical_overlap_fixture" ]]; then
    echo "FAIL: missing physical-link overlap fixture: $physical_overlap_fixture" >&2
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

binary_stl_meshes_match() {
    python3 - "$1" "$2" <<'PY'
import collections
import struct
import sys


def canonical_facet(vertices):
    return min(
        vertices[index:] + vertices[:index]
        for index in range(len(vertices))
    )


def binary_stl_facets(path):
    with open(path, "rb") as stl_file:
        data = stl_file.read()

    if len(data) < 84:
        raise ValueError(f"binary STL is shorter than its header: {path}")

    facet_count, = struct.unpack_from("<I", data, 80)
    expected_size = 84 + 50 * facet_count
    if len(data) != expected_size:
        raise ValueError(
            f"binary STL size mismatch for {path}: "
            f"expected {expected_size}, found {len(data)}"
        )

    facets = []
    for offset in range(84, len(data), 50):
        record = struct.unpack_from("<12fH", data, offset)
        vertices = tuple(
            tuple(record[start:start + 3])
            for start in (3, 6, 9)
        )
        facets.append(canonical_facet(vertices))

    return collections.Counter(facets)


try:
    meshes_match = binary_stl_facets(sys.argv[1]) == binary_stl_facets(sys.argv[2])
except (OSError, ValueError, struct.error) as error:
    print(f"FAIL: cannot compare binary STL meshes: {error}", file=sys.stderr)
    raise SystemExit(2)

raise SystemExit(0 if meshes_match else 1)
PY
}

render_scene() {
    local scene_name="$1"
    local show_hardware="${2:-false}"
    local output_name="$scene_name"

    if [[ "$show_hardware" == "true" ]]; then
        output_name="${scene_name}_hardware"
    fi

    local output_stl="$tmp_dir/${output_name}.stl"
    local summary_json="$tmp_dir/${output_name}.json"

    openscad \
        --export-format asciistl \
        --hardwarnings \
        --summary all \
        --summary-file "$summary_json" \
        -o "$output_stl" \
        -D "scene=\"$scene_name\"" \
        -D "show_hardware=$show_hardware" \
        "$source_model"

    [[ -s "$output_stl" ]]
    jq -e '.geometry.dimensions == 3 and .geometry.simple == true' "$summary_json" >/dev/null
}

render_scene "single_link"
jq -e '
    (.geometry.bounding_box.size[0] - 60 | fabs) < 0.02 and
    (.geometry.bounding_box.size[1] - 20 | fabs) < 0.02 and
    (.geometry.bounding_box.size[2] - 6.7 | fabs) < 0.02
' "$tmp_dir/single_link.json" >/dev/null

openscad \
    --backend CGAL \
    --export-format asciistl \
    --hardwarnings \
    -o "$tmp_dir/single_link_cgal.stl" \
    -D 'scene="single_link"' \
    -D 'show_hardware=false' \
    "$source_model" >"$tmp_dir/single_link_cgal.log" 2>&1

[[ -s "$tmp_dir/single_link_cgal.stl" ]]
if grep -Eq 'CGAL error|PolySet has nonplanar faces|WARNING:|ERROR:' "$tmp_dir/single_link_cgal.log"; then
    cat "$tmp_dir/single_link_cgal.log" >&2
    exit 1
fi

link_components="$(count_ascii_stl_edge_components "$tmp_dir/single_link.stl")"
if [[ "$link_components" != "1" ]]; then
    echo "FAIL: single link exports as $link_components disconnected STL shells" >&2
    exit 1
fi

render_scene "assembled_joint"
jq -e '
    (.geometry.bounding_box.size[0] - 88.2843 | fabs) < 0.05 and
    (.geometry.bounding_box.size[1] - 48.2843 | fabs) < 0.05 and
    (.geometry.bounding_box.size[2] - 12.8 | fabs) < 0.02
' "$tmp_dir/assembled_joint.json" >/dev/null

for angle in 0 15 30 45 60 75 90 105 120 135 150; do
    overlap_stl="$tmp_dir/physical_link_overlap_${angle}.stl"
    overlap_log="$tmp_dir/physical_link_overlap_${angle}.log"

    if openscad \
        --backend CGAL \
        --hardwarnings \
        -o "$overlap_stl" \
        -D "angle=$angle" \
        "$physical_overlap_fixture" >"$overlap_log" 2>&1; then
        overlap_exit=0
    else
        overlap_exit=$?
    fi

    if [[ -s "$overlap_stl" ]]; then
        echo "FAIL: physically flipped links overlap at ${angle} degrees" >&2
        exit 1
    fi

    if [[ "$overlap_exit" != "1" ]]; then
        echo "FAIL: unexpected OpenSCAD exit $overlap_exit at ${angle} degrees" >&2
        cat "$overlap_log" >&2
        exit 1
    fi

    if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$overlap_log"; then
        cat "$overlap_log" >&2
        exit 1
    fi

    grep -q 'Current top level object is empty' "$overlap_log"
done

unsupported_angle_log="$tmp_dir/unsupported_angle.log"
if openscad \
    --hardwarnings \
    -o "$tmp_dir/unsupported_angle.stl" \
    -D 'scene="assembled_joint"' \
    -D 'joint_angle=165' \
    -D 'show_hardware=false' \
    "$source_model" >"$unsupported_angle_log" 2>&1; then
    echo "FAIL: unsupported 165-degree fold was accepted" >&2
    exit 1
fi

grep -q 'Supported joint-angle range is 0 to 150 degrees' "$unsupported_angle_log"

misindexed_angle_log="$tmp_dir/misindexed_angle.log"
if openscad \
    --hardwarnings \
    -o "$tmp_dir/misindexed_angle.stl" \
    -D 'scene="assembled_joint"' \
    -D 'joint_angle=7.5' \
    -D 'show_hardware=false' \
    "$source_model" >"$misindexed_angle_log" 2>&1; then
    echo "FAIL: non-indexed 7.5-degree position was accepted" >&2
    exit 1
fi

grep -q 'Joint angle must use 15-degree indexing' "$misindexed_angle_log"

misphased_overlap_stl="$tmp_dir/joint_overlap_misphased.stl"
misphased_overlap_log="$tmp_dir/joint_overlap_misphased.log"

openscad \
    --hardwarnings \
    -o "$misphased_overlap_stl" \
    -D 'scene="joint_overlap"' \
    -D 'joint_angle=7.5' \
    -D 'show_hardware=false' \
    "$source_model" >"$misphased_overlap_log" 2>&1

[[ -s "$misphased_overlap_stl" ]]
if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$misphased_overlap_log"; then
    cat "$misphased_overlap_log" >&2
    exit 1
fi

for contact_angle in -0.1 0.1; do
    contact_stl="$tmp_dir/joint_contact_${contact_angle}.stl"
    contact_log="$tmp_dir/joint_contact_${contact_angle}.log"

    openscad \
        --hardwarnings \
        -o "$contact_stl" \
        -D 'scene="joint_overlap"' \
        -D "joint_angle=$contact_angle" \
        -D 'overlap_probe_clearance=0' \
        -D 'show_hardware=false' \
        "$source_model" >"$contact_log" 2>&1

    if [[ ! -s "$contact_stl" ]]; then
        echo "FAIL: tooth flanks do not engage immediately at ${contact_angle} degrees" >&2
        cat "$contact_log" >&2
        exit 1
    fi

    if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$contact_log"; then
        cat "$contact_log" >&2
        exit 1
    fi
done

render_scene "exploded_joint" true
render_scene "presentation" true

openscad \
    --backend CGAL \
    --export-format binstl \
    --hardwarnings \
    -o "$tmp_dir/artifact_link.stl" \
    -D 'scene="single_link"' \
    -D 'show_hardware=false' \
    "$source_model" >/dev/null 2>&1

openscad \
    --backend Manifold \
    --export-format binstl \
    --hardwarnings \
    -o "$tmp_dir/artifact_concept.stl" \
    -D 'scene="presentation"' \
    "$source_model" >/dev/null 2>&1

openscad \
    --backend Manifold \
    --render \
    --hardwarnings \
    --imgsize=1200,900 \
    --autocenter \
    --projection=ortho \
    --camera=0,0,0,55,0,25,460 \
    --colorscheme=Tomorrow \
    -o "$tmp_dir/artifact_concept_raw.png" \
    -D 'scene="presentation"' \
    "$source_model" >/dev/null 2>&1

sips \
    -s format png \
    "$tmp_dir/artifact_concept_raw.png" \
    --out "$tmp_dir/artifact_concept.png" >/dev/null

openscad \
    --backend Manifold \
    --render \
    --hardwarnings \
    --imgsize=1200,800 \
    --autocenter \
    --viewall \
    --projection=ortho \
    --camera=0,0,0,55,0,25,140 \
    --colorscheme=Tomorrow \
    -o "$tmp_dir/artifact_detail.png" \
    -D 'scene="exploded_joint"' \
    "$source_model" >/dev/null 2>&1

openscad \
    --backend Manifold \
    --render \
    --hardwarnings \
    --imgsize=1200,800 \
    --autocenter \
    --viewall \
    --projection=ortho \
    --camera=0,0,0,55,0,25,140 \
    --colorscheme=Tomorrow \
    -o "$tmp_dir/artifact_assembled.png" \
    -D 'scene="assembled_joint"' \
    "$source_model" >/dev/null 2>&1

functional_link_artifact="$artifact_dir/2026-07-11_modular_link.stl"
if [[ ! -f "$functional_link_artifact" ]]; then
    echo "FAIL: missing generated artifact: $functional_link_artifact" >&2
    exit 1
fi

if ! binary_stl_meshes_match \
    "$tmp_dir/artifact_link.stl" \
    "$functional_link_artifact"; then
    echo "FAIL: stale generated artifact: $functional_link_artifact" >&2
    exit 1
fi

declare -a artifact_comparisons=(
    "$tmp_dir/artifact_concept.stl|$artifact_dir/2026-07-11_modular_link_joint_concept.stl"
    "$tmp_dir/artifact_concept.png|$artifact_dir/2026-07-11_modular_link_joint_concept.png"
    "$tmp_dir/artifact_detail.png|$artifact_dir/2026-07-11_modular_link_joint_detail.png"
    "$tmp_dir/artifact_assembled.png|$artifact_dir/2026-07-11_modular_link_joint_assembled.png"
)

for comparison in "${artifact_comparisons[@]}"; do
    fresh_artifact="${comparison%%|*}"
    stored_artifact="${comparison#*|}"

    if [[ ! -f "$stored_artifact" ]]; then
        echo "FAIL: missing generated artifact: $stored_artifact" >&2
        exit 1
    fi

    if ! cmp -s "$fresh_artifact" "$stored_artifact"; then
        echo "FAIL: stale generated artifact: $stored_artifact" >&2
        exit 1
    fi
done

echo "PASS: modular-link concept geometry and scenes are valid"
