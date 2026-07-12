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
source_model="$repo_root/models/mechanical_blocks/2026-07-12_lock_prototypes.scad"
artifact_root="$repo_root/stl/2026-07-12/mechanical_block_lock_prototypes"
date_prefix="2026-07-12"

mkdir -p "$artifact_root"

export_part() {
    local prototype="$1"
    local part_name="$2"
    local prototype_dir="$artifact_root/prototype $prototype"
    local output_stl="$prototype_dir/${date_prefix}_prototype_${prototype}_${part_name}.stl"

    mkdir -p "$prototype_dir"

    openscad \
        --backend CGAL \
        --export-format binstl \
        --hardwarnings \
        -o "$output_stl" \
        -D "prototype=$prototype" \
        -D "part=\"$part_name\"" \
        "$source_model"

    [[ -s "$output_stl" ]]
    echo "wrote $output_stl"
}

export_part 1 dovetail_male
export_part 1 dovetail_socket

export_part 2 bayonet_plug
export_part 2 bayonet_socket

export_part 3 snap_hook
export_part 3 snap_socket

export_part 4 wedge_left
export_part 4 wedge_right
export_part 4 wedge_key

export_part 5 t_slider
export_part 5 t_track

export_part 6 split_pin_male
export_part 6 split_pin_socket

export_part 7 thread_plug
export_part 7 thread_socket

export_part 8 detent_slider
export_part 8 detent_track

export_part 9 cam_clamp_body
export_part 9 cam_lever
export_part 9 cam_pin

export_part 10 rack_bar
export_part 10 rack_pawl
