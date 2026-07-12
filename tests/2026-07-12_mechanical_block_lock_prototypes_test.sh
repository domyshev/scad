#!/usr/bin/env bash

set -euo pipefail

if ! command -v openscad >/dev/null 2>&1 && [[ -x /opt/homebrew/bin/openscad ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
command -v openscad >/dev/null 2>&1 || {
    echo "FAIL: OpenSCAD is not installed or not on PATH" >&2
    exit 1
}

command -v jq >/dev/null 2>&1 || {
    echo "FAIL: jq is required for OpenSCAD summary checks" >&2
    exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_model="$repo_root/models/mechanical_blocks/2026-07-12_lock_prototypes.scad"
export_script="$repo_root/scripts/2026-07-12_export_mechanical_block_lock_prototypes.sh"
artifact_root="$repo_root/stl/2026-07-12/mechanical_block_lock_prototypes"
date_prefix="2026-07-12"

if [[ ! -f "$source_model" ]]; then
    echo "FAIL: missing lock prototype source: $source_model" >&2
    exit 1
fi

if [[ ! -x "$export_script" ]]; then
    echo "FAIL: missing executable export script: $export_script" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

count_binary_stl_edge_components() {
    python3 - "$1" <<'PY'
import struct
import sys

with open(sys.argv[1], "rb") as stl_file:
    data = stl_file.read()

if len(data) < 84:
    raise SystemExit("binary STL is shorter than its header")

triangle_count, = struct.unpack_from("<I", data, 80)
expected_size = 84 + 50 * triangle_count
if len(data) != expected_size:
    raise SystemExit(
        f"binary STL size mismatch: expected {expected_size}, found {len(data)}"
    )

triangles = []
for offset in range(84, expected_size, 50):
    record = struct.unpack_from("<12fH", data, offset)
    triangles.append(
        tuple(
            tuple(round(value, 5) for value in record[start:start + 3])
            for start in (3, 6, 9)
        )
    )

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

invalid_edges = sum(1 for incidence in edge_incidence.values() if incidence != 2)
if invalid_edges:
    raise SystemExit(
        f"STL is not watertight: {invalid_edges} edges have incidence != 2"
    )

print(len({find(index) for index in range(len(triangles))}))
PY
}

render_part() {
    local prototype="$1"
    local part_name="$2"
    local out_stl="$tmp_dir/prototype_${prototype}_${part_name}.stl"
    local summary_json="$tmp_dir/prototype_${prototype}_${part_name}.json"
    local log_file="$tmp_dir/prototype_${prototype}_${part_name}.log"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        --summary all \
        --summary-file "$summary_json" \
        -o "$out_stl" \
        -D "prototype=$prototype" \
        -D "part=\"$part_name\"" \
        "$source_model" >"$log_file" 2>&1

    [[ -s "$out_stl" ]]

    if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$log_file"; then
        cat "$log_file" >&2
        exit 1
    fi

    jq -e '
        .geometry.dimensions == 3 and
        .geometry.simple == true and
        (.geometry.bounding_box.size[0] > 2) and
        (.geometry.bounding_box.size[1] > 2) and
        (.geometry.bounding_box.size[2] > 1) and
        (.geometry.bounding_box.size[0] < 80) and
        (.geometry.bounding_box.size[1] < 80) and
        (.geometry.bounding_box.size[2] < 50)
    ' "$summary_json" >/dev/null

    if ! component_count="$(count_binary_stl_edge_components "$out_stl")"; then
        echo "FAIL: prototype $prototype part $part_name is not watertight" >&2
        exit 1
    fi

    if [[ "$component_count" != "1" ]]; then
        echo "FAIL: prototype $prototype part $part_name has $component_count STL edge components" >&2
        exit 1
    fi
}

assert_artifact() {
    local prototype="$1"
    local part_name="$2"
    local prototype_dir="$artifact_root/prototype $prototype"
    local artifact="$prototype_dir/${date_prefix}_prototype_${prototype}_${part_name}.stl"

    if [[ ! -d "$prototype_dir" ]]; then
        echo "FAIL: missing prototype directory: $prototype_dir" >&2
        exit 1
    fi

    if [[ ! -s "$artifact" ]]; then
        echo "FAIL: missing STL artifact: $artifact" >&2
        exit 1
    fi

    case "$(basename "$artifact")" in
        ${date_prefix}_*) ;;
        *)
            echo "FAIL: STL artifact does not start with date prefix: $artifact" >&2
            exit 1
            ;;
    esac

    if ! artifact_component_count="$(count_binary_stl_edge_components "$artifact")"; then
        echo "FAIL: stored artifact is not watertight: $artifact" >&2
        exit 1
    fi

    if [[ "$artifact_component_count" != "1" ]]; then
        echo "FAIL: stored artifact has $artifact_component_count STL edge components: $artifact" >&2
        exit 1
    fi
}

prototype_part_names() {
    case "$1" in
        1) echo "dovetail_male dovetail_socket" ;;
        2) echo "bayonet_plug bayonet_socket" ;;
        3) echo "snap_hook snap_socket" ;;
        4) echo "wedge_left wedge_right wedge_key" ;;
        5) echo "t_slider t_track" ;;
        6) echo "split_pin_male split_pin_socket" ;;
        7) echo "thread_plug thread_socket" ;;
        8) echo "detent_slider detent_track" ;;
        9) echo "cam_clamp_body cam_lever cam_pin" ;;
        10) echo "rack_bar rack_pawl" ;;
        *)
            echo "FAIL: unknown prototype number: $1" >&2
            exit 1
            ;;
    esac
}

for prototype in 1 2 3 4 5 6 7 8 9 10; do
    for part_name in $(prototype_part_names "$prototype"); do
        render_part "$prototype" "$part_name"
        assert_artifact "$prototype" "$part_name"
    done
done

artifact_count="$(find "$artifact_root" -type f -name "${date_prefix}_prototype_*.stl" | wc -l | tr -d ' ')"
if [[ "$artifact_count" != "22" ]]; then
    echo "FAIL: expected 22 dated prototype STL files, found $artifact_count" >&2
    exit 1
fi

find "$artifact_root" -type f -name '*.stl' -print | while IFS= read -r stl_file; do
    if [[ "$(basename "$stl_file")" != ${date_prefix}_* ]]; then
        echo "FAIL: STL without required date prefix: $stl_file" >&2
        exit 1
    fi
done

echo "PASS: mechanical block lock prototype STL scenes and artifacts are valid"
