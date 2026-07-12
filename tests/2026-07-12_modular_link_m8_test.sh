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
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_m8.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_m8.sh"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"
artifact_root="$repo_root/stl/2026-07-12/modular_link_m8"
date_prefix="2026-07-12"

if [[ ! -f "$source_model" ]]; then
    echo "FAIL: missing M8 modular-link source: $source_model" >&2
    exit 1
fi

if [[ ! -x "$export_script" ]]; then
    echo "FAIL: missing executable M8 export script: $export_script" >&2
    exit 1
fi

if [[ ! -f "$auditor" ]]; then
    echo "FAIL: missing STL mesh auditor: $auditor" >&2
    exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

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
            tuple(round(value, 5) for value in record[start:start + 3])
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
    local angle="${2:-45}"
    local out_stl="$tmp_dir/${scene_name}_${angle}.stl"
    local summary_json="$tmp_dir/${scene_name}_${angle}.json"
    local log_file="$tmp_dir/${scene_name}_${angle}.log"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        --summary all \
        --summary-file "$summary_json" \
        -o "$out_stl" \
        -D "scene=\"$scene_name\"" \
        -D "joint_angle=$angle" \
        -D 'show_hardware=false' \
        "$source_model" >"$log_file" 2>&1

    [[ -s "$out_stl" ]]

    if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$log_file"; then
        cat "$log_file" >&2
        exit 1
    fi

    grep -q 'M8_LINK tooth_count=48 step_angle=7.5 joint_d=24 bolt_clearance_d=8.8 tooth_inner_d=12 tooth_outer_d=22' "$log_file"
    jq -e '.geometry.dimensions == 3 and .geometry.simple == true' "$summary_json" >/dev/null
}

artifact_path="$artifact_root/${date_prefix}_modular_link_7_5deg_m8.stl"

render_scene single_link
jq -e '
    ((.geometry.bounding_box.size[0] - 64) | fabs) < 0.02 and
    ((.geometry.bounding_box.size[1] - 24) | fabs) < 0.02 and
    ((.geometry.bounding_box.size[2] - 6.7) | fabs) < 0.02
' "$tmp_dir/single_link_45.json" >/dev/null
python3 "$auditor" --expected-components 1 "$tmp_dir/single_link_45.stl" >/dev/null

for angle in 0 7.5 15 30 45 90 135 180; do
    render_scene assembled_joint "$angle"
done

misindexed_angle_log="$tmp_dir/misindexed_angle.log"
if openscad \
    --backend CGAL \
    --hardwarnings \
    -o "$tmp_dir/misindexed_angle.stl" \
    -D 'scene="assembled_joint"' \
    -D 'joint_angle=11.25' \
    -D 'show_hardware=false' \
    "$source_model" >"$misindexed_angle_log" 2>&1; then
    echo "FAIL: non-indexed 11.25-degree M8 position was accepted" >&2
    exit 1
fi
grep -q 'Joint angle must use 7.5-degree indexing' "$misindexed_angle_log"

if [[ ! -s "$artifact_path" ]]; then
    echo "FAIL: missing STL artifact: $artifact_path" >&2
    exit 1
fi

case "$(basename "$artifact_path")" in
    ${date_prefix}_*) ;;
    *)
        echo "FAIL: STL artifact does not start with date prefix: $artifact_path" >&2
        exit 1
        ;;
esac

python3 "$auditor" --expected-components 1 "$artifact_path" >/dev/null

artifact_count="$(find "$artifact_root" -maxdepth 1 -type f -name "${date_prefix}_modular_link_7_5deg_m8.stl" | wc -l | tr -d ' ')"
if [[ "$artifact_count" != "1" ]]; then
    echo "FAIL: expected 1 dated M8 STL file, found $artifact_count" >&2
    exit 1
fi

find "$artifact_root" -type f -name '*.stl' -print | while IFS= read -r stl_file; do
    if [[ "$(basename "$stl_file")" != ${date_prefix}_* ]]; then
        echo "FAIL: STL without required date prefix: $stl_file" >&2
        exit 1
    fi
done

fresh_export_root="$tmp_dir/fresh_export"
"$export_script" "$fresh_export_root" >/dev/null
fresh_artifact="$fresh_export_root/$(basename "$artifact_path")"

if [[ ! -s "$fresh_artifact" ]]; then
    echo "FAIL: fresh export did not create $fresh_artifact" >&2
    exit 1
fi

if ! binary_stl_meshes_match "$fresh_artifact" "$artifact_path"; then
    echo "FAIL: stale generated artifact: $artifact_path" >&2
    exit 1
fi

echo "PASS: M8 modular-link geometry and artifact are valid"
