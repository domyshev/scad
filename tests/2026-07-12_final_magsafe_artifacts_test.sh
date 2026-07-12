#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
artifact_dir="$repo_root/stl/2026-07-11"
exporter="$repo_root/scripts/2026-07-11_export_triangular_magsafe_stand.sh"
auditor="$repo_root/tests/2026-07-11_stl_mesh_audit.py"

[[ -x "$exporter" ]]
[[ -x "$auditor" ]]

declare -a single_component_parts=(
    "2026-07-11_modular_link.stl"
    "2026-07-11_magsafe_fit_gauge.stl"
    "2026-07-11_magsafe_bridge_holder.stl"
    "2026-07-11_ballast_cassette_body.stl"
    "2026-07-11_ballast_cassette_lid.stl"
    "2026-07-11_joint_spacer.stl"
)

for filename in "${single_component_parts[@]}"; do
    path="$artifact_dir/$filename"
    [[ -s "$path" ]]
    python3 "$auditor" --expected-components 1 "$path" >/dev/null
done

fit_pair="$artifact_dir/2026-07-11_modular_link_fit_pair.stl"
[[ -s "$fit_pair" ]]
python3 "$auditor" --expected-components 2 "$fit_pair" >/dev/null

preview="$artifact_dir/2026-07-11_triangular_magsafe_stand_preview.stl"
[[ -s "$preview" ]]
# The assembled preview intentionally contains touching printed parts,
# M4 hardware, a MagSafe puck and a phone envelope. It is visual-only and is
# therefore not judged by the single-print topology rule above.

for view in overall side exploded; do
    image="$artifact_dir/2026-07-11_triangular_magsafe_stand_${view}.png"
    [[ -s "$image" ]]
done

echo "PASS: final MagSafe stand artifacts are present and valid"
