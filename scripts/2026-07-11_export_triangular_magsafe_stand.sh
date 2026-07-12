#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
link_model="$repo_root/models/iphone_holder/2026-07-11_modular_link_concept.scad"
stand_model="$repo_root/models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"
output_dir="${1:-$repo_root/stl/2026-07-11}"

if command -v openscad >/dev/null 2>&1; then
    openscad_bin="$(command -v openscad)"
elif [[ -x /opt/homebrew/bin/openscad ]]; then
    openscad_bin=/opt/homebrew/bin/openscad
else
    echo "FAIL: OpenSCAD is not installed or not on PATH" >&2
    exit 1
fi

mkdir -p "$output_dir"

export_stl() {
    local model="$1"
    local scene_name="$2"
    local filename="$3"
    local backend="${4:-CGAL}"
    local expected_components="${5:-1}"
    local output="$output_dir/$filename"

    "$openscad_bin" \
        --backend "$backend" \
        --hardwarnings \
        --export-format binstl \
        -o "$output" \
        -D "scene=\"$scene_name\"" \
        -D 'show_hardware=false' \
        "$model" >/dev/null 2>&1

    [[ -s "$output" ]]
    if [[ "$expected_components" == "visual" ]]; then
        echo "VISUAL ONLY: $filename is a touching multi-part assembly"
    elif [[ "$expected_components" == "any" ]]; then
        python3 "$auditor" --expected-components-any "$output"
    else
        python3 "$auditor" \
            --expected-components "$expected_components" \
            "$output"
    fi
}

render_png() {
    local scene_name="$1"
    local filename="$2"
    local camera="$3"
    local output="$output_dir/$filename"

    "$openscad_bin" \
        --backend Manifold \
        --render \
        --hardwarnings \
        --imgsize=1600,1200 \
        --autocenter \
        --viewall \
        --projection=ortho \
        --camera="$camera" \
        --colorscheme=Tomorrow \
        -o "$output" \
        -D "scene=\"$scene_name\"" \
        -D 'show_hardware=true' \
        "$stand_model" >/dev/null 2>&1

    [[ -s "$output" ]]
}

export_stl \
    "$link_model" single_link \
    2026-07-11_modular_link.stl CGAL 1
export_stl \
    "$link_model" fit_pair_print \
    2026-07-11_modular_link_fit_pair.stl CGAL 2
export_stl \
    "$stand_model" magsafe_fit_gauge \
    2026-07-11_magsafe_fit_gauge.stl CGAL 1
export_stl \
    "$stand_model" magsafe_bridge_holder \
    2026-07-11_magsafe_bridge_holder.stl CGAL 1
export_stl \
    "$stand_model" ballast_body \
    2026-07-11_ballast_cassette_body.stl CGAL 1
export_stl \
    "$stand_model" ballast_lid \
    2026-07-11_ballast_cassette_lid.stl CGAL 1
export_stl \
    "$stand_model" joint_spacer \
    2026-07-11_joint_spacer.stl CGAL 1

# This STL is a visual multi-part assembly, not a one-piece print.
export_stl \
    "$stand_model" stand_preview \
    2026-07-11_triangular_magsafe_stand_preview.stl Manifold visual

render_png \
    stand_preview \
    2026-07-11_triangular_magsafe_stand_overall.png \
    0,0,0,62,0,35,260
render_png \
    stand_preview \
    2026-07-11_triangular_magsafe_stand_side.png \
    0,-250,55,0,0,40
render_png \
    stand_exploded \
    2026-07-11_triangular_magsafe_stand_exploded.png \
    0,0,0,62,0,35,330

echo "PASS: exported triangular MagSafe stand artifacts to $output_dir"
