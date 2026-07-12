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
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_m8_fasteners.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_m8_fasteners.sh"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"
artifact_root="$repo_root/stl/2026-07-12/modular_link_m8"
date_prefix="2026-07-12"

if [[ ! -f "$source_model" ]]; then
    echo "FAIL: missing M8 fastener source: $source_model" >&2
    exit 1
fi

if [[ ! -x "$export_script" ]]; then
    echo "FAIL: missing executable M8 fastener export script: $export_script" >&2
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

artifact_path() {
    case "$1" in
        hex_bolt)
            echo "$artifact_root/${date_prefix}_modular_link_m8_hex_bolt.stl"
            ;;
        hex_nut)
            echo "$artifact_root/${date_prefix}_modular_link_m8_hex_nut.stl"
            ;;
        *)
            echo "FAIL: unknown M8 fastener part: $1" >&2
            exit 1
            ;;
    esac
}

render_part() {
    local part_name="$1"
    local expected_x="$2"
    local expected_y="$3"
    local expected_z="$4"
    local tolerance="$5"
    local out_stl="$tmp_dir/${part_name}.stl"
    local summary_json="$tmp_dir/${part_name}.json"
    local log_file="$tmp_dir/${part_name}.log"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        --summary all \
        --summary-file "$summary_json" \
        -o "$out_stl" \
        -D "part=\"$part_name\"" \
        "$source_model" >"$log_file" 2>&1

    [[ -s "$out_stl" ]]

    if grep -Eq '^WARNING:|^ERROR:|CGAL error|PolySet has nonplanar faces' "$log_file"; then
        cat "$log_file" >&2
        exit 1
    fi

    grep -q 'M8_FASTENER_PARAMETERS' "$log_file"
    grep -q 'bolt_outer_d=8.4' "$log_file"
    grep -q 'thread_pitch=1.5' "$log_file"
    grep -q 'thread_size=1' "$log_file"
    grep -q 'nut_thread_cut_d=9' "$log_file"
    grep -q 'link_bolt_clearance_d=8.8' "$log_file"
    grep -q 'assembly_stack_h=12.8' "$log_file"

    jq -e \
        --argjson x "$expected_x" \
        --argjson y "$expected_y" \
        --argjson z "$expected_z" \
        --argjson tol "$tolerance" '
        .geometry.dimensions == 3 and
        .geometry.simple == true and
        ((.geometry.bounding_box.size[0] - $x) | fabs) < $tol and
        ((.geometry.bounding_box.size[1] - $y) | fabs) < $tol and
        ((.geometry.bounding_box.size[2] - $z) | fabs) < $tol
    ' "$summary_json" >/dev/null

    python3 "$auditor" --expected-components 1 "$out_stl" >/dev/null
}

assert_artifact() {
    local part_name="$1"
    local artifact
    artifact="$(artifact_path "$part_name")"

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

    python3 "$auditor" --expected-components 1 "$artifact" >/dev/null
}

render_part hex_bolt 15.0111 13 31.5 0.08
render_part hex_nut 15.0111 13 7 0.08

for part_name in hex_bolt hex_nut; do
    assert_artifact "$part_name"
done

for filename in \
    "${date_prefix}_modular_link_m8_hex_bolt.stl" \
    "${date_prefix}_modular_link_m8_hex_nut.stl"; do
    if [[ ! -s "$artifact_root/$filename" ]]; then
        echo "FAIL: missing expected fastener artifact in M8 folder: $filename" >&2
        exit 1
    fi
done

find "$artifact_root" -maxdepth 1 -type f -name '*m8_hex_*.stl' -print | while IFS= read -r stl_file; do
    if [[ "$(basename "$stl_file")" != ${date_prefix}_* ]]; then
        echo "FAIL: STL without required date prefix: $stl_file" >&2
        exit 1
    fi
done

fresh_export_root="$tmp_dir/fresh_export"
"$export_script" "$fresh_export_root" >/dev/null

for part_name in hex_bolt hex_nut; do
    stored_artifact="$(artifact_path "$part_name")"
    fresh_artifact="$fresh_export_root/$(basename "$stored_artifact")"

    if [[ ! -s "$fresh_artifact" ]]; then
        echo "FAIL: fresh export did not create $fresh_artifact" >&2
        exit 1
    fi

    if ! binary_stl_meshes_match "$fresh_artifact" "$stored_artifact"; then
        echo "FAIL: stale generated artifact: $stored_artifact" >&2
        exit 1
    fi
done

echo "PASS: M8 modular-link fasteners are valid"
