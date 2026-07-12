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
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_printed_fasteners.scad"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"
output_dir="${1:-$repo_root/stl/2026-07-12/modular_link_fasteners}"
date_prefix="2026-07-12"

mkdir -p "$output_dir"

export_part() {
    local part_name="$1"
    local filename="$2"
    local output_stl="$output_dir/$filename"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        -o "$output_stl" \
        -D "part=\"$part_name\"" \
        "$source_model" >/dev/null 2>&1

    [[ -s "$output_stl" ]]
    python3 "$auditor" --expected-components 1 "$output_stl" >/dev/null
    echo "wrote $output_stl"
}

export_part hex_bolt "${date_prefix}_modular_link_hex_bolt.stl"
export_part hex_nut "${date_prefix}_modular_link_hex_nut.stl"
export_part wing_nut "${date_prefix}_modular_link_wing_nut.stl"

echo "PASS: exported modular-link printed fasteners to $output_dir"
