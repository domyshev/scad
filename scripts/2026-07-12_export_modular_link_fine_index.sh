#!/usr/bin/env bash

set -euo pipefail

if ! command -v openscad >/dev/null 2>&1 && [[ -x /opt/homebrew/bin/openscad ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
command -v openscad >/dev/null 2>&1 || {
    echo "FAIL: OpenSCAD is not installed or not on PATH" >&2
    exit 1
}

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_fine_index.scad"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"
output_dir="${1:-$repo_root/stl/2026-07-12/modular_link_fine_index}"
date_prefix="2026-07-12"

mkdir -p "$output_dir"

export_scene() {
    local scene_name="$1"
    local filename="$2"
    local expected_components="$3"
    local output_stl="$output_dir/$filename"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        -o "$output_stl" \
        -D "scene=\"$scene_name\"" \
        -D 'show_hardware=false' \
        "$source_model" >/dev/null 2>&1

    [[ -s "$output_stl" ]]
    python3 "$auditor" --expected-components "$expected_components" "$output_stl" >/dev/null
    echo "wrote $output_stl"
}

export_scene single_link "${date_prefix}_modular_link_7_5deg.stl" 1
export_scene fit_pair_print "${date_prefix}_modular_link_7_5deg_fit_pair.stl" 2

echo "PASS: exported fine-index modular-link artifacts to $output_dir"
