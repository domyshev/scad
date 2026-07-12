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
link_model="$repo_root/models/iphone_holder/2026-07-11_modular_link_concept.scad"
stand_model="$repo_root/models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

render_dispatch_scene() {
    local model="$1"
    local scene_name="$2"
    local output="$tmp_dir/${scene_name}.csg"
    local log="$tmp_dir/${scene_name}.log"

    openscad \
        --hardwarnings \
        -o "$output" \
        -D "scene=\"$scene_name\"" \
        -D 'show_hardware=false' \
        "$model" >"$log" 2>&1

    if grep -Eq '^ERROR:|^WARNING:' "$log"; then
        cat "$log" >&2
        return 1
    fi

    [[ -s "$output" ]]
}

render_dispatch_scene "$link_model" "fit_pair_print"
render_dispatch_scene "$stand_model" "stand_preview"
render_dispatch_scene "$stand_model" "stand_exploded"

echo "PASS: final export scenes are dispatched"
