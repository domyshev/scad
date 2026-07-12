# Triangular MagSafe Link Stand Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a tested OpenSCAD model, separate printable STL files, and visual assembly renders for a two-frame triangular iPhone stand with an internal steel-ballast cassette and an official MagSafe puck holder.

**Architecture:** Repair the reusable one-sided modular link first, using a reflection-symmetric radial face coupling that works when a real second print is rotated 180°. Build the stand in one focused OpenSCAD source that imports the link API, positions twelve links in two aligned six-link triangles, and adds three bounded components: a captive ballast cassette, two spacers, and a one-piece apex bridge/MagSafe cup. A shell test suite drives CGAL exports, validates dimensions and collisions, and compares regenerated dated artifacts with the checked-in files.

**Tech Stack:** OpenSCAD 2026.06.12, Bash, jq, Python 3 standard library, macOS `sips`, Git.

## Global Constraints

- All dated artifacts under `stl/2026-07-11/` must begin with `2026-07-11_`.
- Final functional STL exports use the CGAL backend; Manifold is accepted only after an explicit matching audit.
- Standard link: 40 mm joint pitch, 20 mm width/joint diameter, 6 mm body, 4.6 mm M4 clearance, 24 teeth, 15° indexed positions from 0° through 150°.
- Stand frame: two six-link equilateral frames, 80 mm centerline side, nominal outer envelope 100 × 89.3 × 90 mm.
- Ballast cavity: at least 130 cm³ after walls, M4 sleeves, lid rails, and ribs; assembled stand target mass is at least 800 g without the phone.
- Default puck preset: Apple A2580/A3250 at 55.50 × 4.37 mm; alternate A2140 preset is 55.90 × 5.30 mm.
- MagSafe face angle is 75° to the table, cup outer diameter is at most 60 mm, diameter clearance is 0.35 mm, face proud is 0.4 mm, cable slot is 4.1 mm, and guide bend radius is at least 12 mm.
- First functional print material is PETG; every modeled printable part must have a support-free intended orientation.
- Every commit needs a concise subject and a detailed body describing files, parameters, artifacts, and verification.

---

### Task 1: Make identical modular links physically mate

**Files:**
- Create: `tests/fixtures/2026-07-11_physical_link_overlap.scad`
- Modify: `models/iphone_holder/2026-07-11_modular_link_concept.scad`
- Modify: `tests/2026-07-11_modular_link_concept_test.sh`
- Regenerate: `stl/2026-07-11/2026-07-11_modular_link.stl`
- Regenerate: `stl/2026-07-11/2026-07-11_modular_link_joint_concept.stl`
- Regenerate: `stl/2026-07-11/2026-07-11_modular_link_joint_concept.png`
- Regenerate: `stl/2026-07-11/2026-07-11_modular_link_joint_detail.png`
- Regenerate: `stl/2026-07-11/2026-07-11_modular_link_joint_assembled.png`

**Interfaces:**
- Produces: `modular_link()`, `lower_link_at_joint()`, `upper_link_at_joint(angle, separation, validate_angle)`, and accessor functions `modular_link_pitch()`, `modular_joint_d()`, `modular_link_body_h()`, `modular_link_stack_h()`, `modular_bolt_clearance_d()`.
- Produces: `physical_link_pair(angle, separation)` and `joint_overlap()` using a physical `rotate([180, 0, 0])` transform.
- Consumes: no files from later tasks.

- [x] **Step 1: Add a physical-flip regression fixture and make the shell test use CGAL**

```scad
// tests/fixtures/2026-07-11_physical_link_overlap.scad
use <../../models/iphone_holder/2026-07-11_modular_link_concept.scad>

angle = 45;
probe_clearance = 0.01;

intersection() {
    translate([-20, 0, 0]) modular_link();
    translate([0, 0, 12.8 + probe_clearance])
        rotate([0, 0, angle])
            translate([20, 0, 0])
                rotate([180, 0, 0])
                    modular_link();
}
```

In `tests/2026-07-11_modular_link_concept_test.sh`, render this fixture for every angle in `0 15 ... 150` with `--backend CGAL`; a non-empty STL is a failure. Keep the 7.5° misphase check non-empty.

- [x] **Step 2: Run the physical-flip test and verify the current model fails**

Run:

```bash
bash tests/2026-07-11_modular_link_concept_test.sh
```

Expected: FAIL at the first physical-flip overlap, with a non-empty intersection near 4.185 mm³.

- [x] **Step 3: Replace chiral sector diagonals with reflection-symmetric center fans**

Add public accessors and replace the two-triangle top sector with four triangles around a midpoint. Apply the same reflection-symmetric fan construction to the top, bottom, outer, and inner sector surfaces so neither backend chooses a chiral diagonal.

```scad
function modular_link_pitch() = link_pitch;
function modular_joint_d() = joint_d;
function modular_link_body_h() = link_thickness;
function modular_link_stack_h() = assembly_stack_h;
function modular_bolt_clearance_d() = bolt_clearance_d;

function sector_midpoint(radius, station_index, z_position) =
    polar3(
        radius,
        (station_index + 0.5) * serration_step_angle,
        z_position
    );

// For each angular sector, top boundary order is
// top_inner_i -> top_outer_i -> top_outer_next -> top_inner_next.
// Add one point at mid-radius/mid-angle/z=(height_i+height_next)/2 and
// emit the four consistently oriented fan triangles around that point.
```

Change the assembled upper link to the real transform:

```scad
translate([0, 0, assembly_stack_h + separation])
    rotate([0, 0, angle])
        translate([link_pitch / 2, 0, 0])
            rotate([180, 0, 0])
                modular_link();
```

- [x] **Step 4: Run the complete link test and verify green geometry**

Run:

```bash
bash tests/2026-07-11_modular_link_concept_test.sh
```

Expected: PASS for dimensions, watertight one-shell link, all eleven indexed physical assemblies, immediate flank engagement around 0°, and rejected 7.5°/165° inputs.

- [x] **Step 5: Commit the repaired link**

```bash
git add models/iphone_holder/2026-07-11_modular_link_concept.scad \
  tests/fixtures/2026-07-11_physical_link_overlap.scad \
  tests/2026-07-11_modular_link_concept_test.sh stl/2026-07-11
git commit -m "Repair physical modular-link coupling" \
  -m "Replace chiral radial-sector triangulation with reflection-symmetric facets so two identical prints mate after a real 180-degree flip. Add CGAL physical-overlap regressions for every 15-degree index, regenerate the dated link STL and joint renders, and verify watertight single-shell exports."
```

### Task 2: Build and test the two-frame triangular skeleton

**Files:**
- Create: `models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad`
- Create: `tests/2026-07-11_triangular_magsafe_stand_test.sh`

**Interfaces:**
- Consumes: Task 1 accessors and `modular_link()`.
- Produces: `frame_link(node_a, node_b, upper_layer)`, `triangle_frame(y_reference)`, `frame_pair()`, `joint_spacer()`, `cross_rod(node)`, and scene names `frame_pair`, `joint_spacer`, `frame_envelope`.
- Produces shared constants `frame_side = 80`, `frame_depth = 90`, `frame_inner_gap = 64.4`, `frame_height = 80 * sqrt(3) / 2`, and ordered `frame_nodes`.

- [x] **Step 1: Write failing frame-envelope and scene tests**

The shell test must render every named scene with `--backend CGAL --hardwarnings --summary all`. Assert:

```bash
jq -e '
  (.geometry.bounding_box.size[0] - 100 | fabs) < 0.5 and
  (.geometry.bounding_box.size[1] - 90 | fabs) < 0.5 and
  (.geometry.bounding_box.size[2] - 89.282 | fabs) < 0.5
' "$tmp_dir/frame_envelope.json"
```

Also render `joint_spacer` and require one simple 3D shell with a 64.4 ± 0.05 mm long axis and a 4.8 mm nominal teardrop through-hole.

- [x] **Step 2: Run the stand test and verify missing scenes fail**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: FAIL because `2026-07-11_triangular_magsafe_stand.scad` or its scenes do not exist.

- [x] **Step 3: Implement the frame nodes and alternating link layers**

Use these exact centerline nodes in clockwise order:

```scad
frame_nodes = [
    [-40, 0],
    [-20, frame_height / 2],
    [0, frame_height],
    [20, frame_height / 2],
    [40, 0],
    [0, 0]
];

module frame_link(node_a, node_b, upper_layer = false) {
    dx = node_b[0] - node_a[0];
    dz = node_b[1] - node_a[1];
    angle = atan2(dz, dx);
    midpoint = [(node_a[0] + node_b[0]) / 2,
                (node_a[1] + node_b[1]) / 2];

    translate([midpoint[0], 0, midpoint[1]])
        rotate([0, -angle, 0])
            rotate([90, 0, 0])
                if (upper_layer)
                    translate([0, 0, modular_link_stack_h()])
                        rotate([180, 0, 0]) modular_link();
                else
                    modular_link();
}
```

Alternate `upper_layer` by segment index. Place frame reference planes at `y = -32.2` and `y = 45`, producing outer faces at -45 and +45 and an inner clear gap of 64.4 mm.

- [x] **Step 4: Add preview rods and support-free spacer**

Use a 64.4 mm long rectangular spacer with rounded outside corners and a horizontal 4.8 mm teardrop bore. In assembly scenes, show six 4 mm rods centered at the six frame nodes; hardware is preview geometry only and never unioned with printable STL scenes.

- [x] **Step 5: Run tests and commit the skeleton**

Run:

```bash
bash tests/2026-07-11_modular_link_concept_test.sh
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: both scripts PASS through the frame and spacer assertions.

Commit:

```bash
git add models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad \
  tests/2026-07-11_triangular_magsafe_stand_test.sh
git commit -m "Build triangular modular-link frame" \
  -m "Add the parameterized two-frame 80 mm-side triangular skeleton, alternate real link layers, model six cross-axis locations and a support-free 64.4 mm spacer, and verify the 100 by 89.3 by 90 mm envelope with CGAL scene tests."
```

### Task 3: Add the captive internal ballast cassette

**Files:**
- Modify: `models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad`
- Modify: `tests/2026-07-11_triangular_magsafe_stand_test.sh`

**Interfaces:**
- Consumes: `frame_inner_gap`, lower frame nodes at `[-40, 0]`, `[0, 0]`, `[40, 0]`.
- Produces: `ballast_outer()`, `ballast_void()`, `ballast_cassette_body()`, `ballast_cassette_lid()`, and scenes `ballast_body`, `ballast_lid`, `ballast_void`, `frame_ballast_overlap`.

- [x] **Step 1: Add failing cavity-volume and collision assertions**

Render `ballast_void` with JSON summary and require volume at least 130000 mm³. Render `frame_ballast_overlap` with a 0.05 mm contact probe; the expected result is an empty top-level object. Render body and lid separately and require simple one-shell geometry with positive volume.

- [x] **Step 2: Run the stand test and verify the missing ballast scenes fail**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: FAIL because `ballast_void` is unknown.

- [x] **Step 3: Implement the trapezoidal shell, three M4 sleeves, and open cavity**

Use this nominal outer side profile in the `x/z` plane and extrude it 64.0 mm across `y`:

```scad
ballast_profile = [
    [-45, -8],
    [45, -8],
    [32, 32],
    [-32, 32]
];
```

Subtract a 2.4 mm side/end-wall cavity above a 3 mm bottom. Union three 10 mm OD sleeves at x = -40, 0, +40 and z = 0, each 64.4 mm long, then subtract a 4.8 mm horizontal teardrop bore. Keep 4.5 mm solid material around every sleeve. The `ballast_void()` diagnostic scene is the actual fillable cavity after subtracting the sleeves and lid rails, not a bounding-box estimate.

- [x] **Step 4: Implement the sliding lid and enforce print clearances**

Use 1.3 mm deep rails, 0.28 mm clearance per side, a 2.4 mm plate, a stepped labyrinth edge, and a 1.9 mm transverse hole for a 1.75 mm filament retaining pin. The body prints with its flat bottom on the bed; the lid prints flat.

- [x] **Step 5: Run tests and commit the cassette**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: PASS, including reported fillable volume ≥130 cm³, empty frame/cassette probe, and valid body/lid shells.

Commit:

```bash
git add models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad \
  tests/2026-07-11_triangular_magsafe_stand_test.sh
git commit -m "Add internal steel-ballast cassette" \
  -m "Model the low captive trapezoidal cassette between the triangular frames with three structural M4 sleeves, a measured 130 cm3 minimum fill cavity, support-free PETG walls, and a pinned sliding labyrinth lid. Add CGAL volume, shell, and frame-clearance regressions."
```

### Task 4: Add the one-piece MagSafe bridge and fit gauge

**Files:**
- Modify: `models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad`
- Modify: `tests/2026-07-11_triangular_magsafe_stand_test.sh`

**Interfaces:**
- Consumes: apex node `[0, frame_height]`, `frame_inner_gap`, one top M4 cross-axis.
- Produces: `magsafe_cup(puck_d, puck_h)`, `magsafe_fit_gauge(puck_d, puck_h)`, `apex_key()`, `magsafe_bridge_holder()`, `phone_envelope()`, and scenes `magsafe_fit_gauge`, `magsafe_bridge_holder`, `phone_table_overlap`, `frame_holder_overlap`.

- [x] **Step 1: Add failing MagSafe dimension, table-clearance, and collision tests**

Render the default fit gauge and holder. Require holder outer cup diameter ≤60.0 mm, default cavity diameter 55.85 ± 0.05 mm, puck recess 3.97 ± 0.05 mm so a 4.37 mm puck is proud by 0.4 mm, and a 4.1 ± 0.05 mm open cable slot. Render `phone_table_overlap` and `frame_holder_overlap`; both must be empty with a 0.05 mm probe. Invoke `puck_preset="a2140"` and assert the cavity changes to 56.25 ± 0.05 mm and depth to 4.90 ± 0.05 mm.

- [x] **Step 2: Run the stand test and verify the missing MagSafe scene fails**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: FAIL because `magsafe_fit_gauge` is unknown.

- [x] **Step 3: Implement the split cup and cable path**

Build a 60 mm OD cup with a 2.4 mm back wall. Subtract `puck_d + 0.35` and stop the wall 0.4 mm below the aluminum face. Add three 120°-spaced PETG detent tabs below the face and subtract a radial 4.1 mm open slot toward the lower cable direction. Add a 20 mm straight cable cradle followed by a 12 mm-radius open guide; do not create a closed USB-C tunnel.

- [x] **Step 4: Implement the apex bridge and anti-rotation keys**

Place puck center at `[15, 0, 96]`. Orient the face 75° to the table. Use a 64.4 mm M4 cross-tube through the apex and a thin V-shaped key at each inner frame face; each key bears against both apex link bodies so the holder cannot rotate solely on bolt friction. Connect the tube to the cup back with two symmetric 45° gussets. Provide a separate print transform that places the cup back and bridge ribs on the bed without support.

- [x] **Step 5: Run tests and commit the MagSafe parts**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: PASS for both Apple presets, empty collision probes, ≥8 mm phone/table clearance, and valid one-shell fit-gauge and bridge-holder exports.

Commit:

```bash
git add models/iphone_holder/2026-07-11_triangular_magsafe_stand.scad \
  tests/2026-07-11_triangular_magsafe_stand_test.sh
git commit -m "Add apex MagSafe bridge and gauge" \
  -m "Create the one-piece keyed apex bridge and 75-degree official MagSafe cup with A2580/A3250 and A2140 presets, PETG detents, a 4.1 mm open cable path and a support-free print transform. Add fit, clearance, collision and phone-table regressions."
```

### Task 5: Export, audit, and visually inspect the complete print set

**Files:**
- Create: `scripts/2026-07-11_export_triangular_magsafe_stand.sh`
- Create: `tests/2026-07-11_stl_mesh_audit.py`
- Modify: `tests/2026-07-11_triangular_magsafe_stand_test.sh`
- Create/Regenerate: `stl/2026-07-11/2026-07-11_modular_link_fit_pair.stl`
- Create: `stl/2026-07-11/2026-07-11_magsafe_fit_gauge.stl`
- Create: `stl/2026-07-11/2026-07-11_magsafe_bridge_holder.stl`
- Create: `stl/2026-07-11/2026-07-11_ballast_cassette_body.stl`
- Create: `stl/2026-07-11/2026-07-11_ballast_cassette_lid.stl`
- Create: `stl/2026-07-11/2026-07-11_joint_spacer.stl`
- Create: `stl/2026-07-11/2026-07-11_triangular_magsafe_stand_preview.stl`
- Create: `stl/2026-07-11/2026-07-11_triangular_magsafe_stand_overall.png`
- Create: `stl/2026-07-11/2026-07-11_triangular_magsafe_stand_side.png`
- Create: `stl/2026-07-11/2026-07-11_triangular_magsafe_stand_exploded.png`

**Interfaces:**
- Consumes: every printable and preview scene from Tasks 1–4.
- Produces: deterministic dated artifact set and a command-line mesh audit that returns nonzero for a non-watertight mesh, an unexpected component count, non-positive signed volume, or edge incidence other than two.

- [x] **Step 1: Write the failing artifact-presence and mesh-audit loop**

The test must call the export script in a temporary directory, audit every printable STL, and compare each fresh output byte-for-byte with the stored dated artifact. Each individual part requires exactly one component; `modular_link_fit_pair.stl` requires exactly two. The preview STL is audited for watertight component shells and positive total volume with its explicit assembly component count, and is labelled non-printable in the script output.

- [x] **Step 2: Run the test and verify missing exporter/artifacts fail**

Run:

```bash
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: FAIL because the export script and final artifact set are absent.

- [x] **Step 3: Implement the standard-library STL auditor**

Parse both binary and ASCII STL. Quantize vertices to 1e-6 mm, count each undirected edge, union triangles sharing an edge, calculate signed tetrahedral volume, and report JSON containing `triangles`, `components`, `invalid_edges`, and `volume_mm3`. Accept `--expected-components N`; exit nonzero unless `components == N`, `invalid_edges == 0`, and `volume_mm3 > 0`.

- [x] **Step 4: Implement deterministic CGAL exports and three PNG views**

For each STL use:

```bash
openscad --backend CGAL --hardwarnings --export-format binstl \
  -o "$output" -D "scene=\"$scene\"" "$stand_model"
```

For renders use `--backend CGAL --render --imgsize=1600,1200 --projection=ortho`, fixed cameras for overall, side, and exploded scenes, and convert to PNG with `sips` only when OpenSCAD emits another bitmap format.

- [x] **Step 5: Regenerate artifacts, run both suites, and inspect the images**

Run:

```bash
bash scripts/2026-07-11_export_triangular_magsafe_stand.sh stl/2026-07-11
bash tests/2026-07-11_modular_link_concept_test.sh
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
```

Expected: both test scripts PASS; individual-part audits report one component, the fit-pair audit reports two, the preview reports its explicit assembly count, and all report zero invalid edges with positive volume. Open all three PNG files with the workspace image viewer and verify the phone is on the +x side, ballast is visibly inside the lower triangle, both frames are present, the cup is centered across `y`, cable routing is open, and no part floats or intersects.

- [x] **Step 6: Commit the audited artifact set**

```bash
git add scripts/2026-07-11_export_triangular_magsafe_stand.sh \
  tests/2026-07-11_stl_mesh_audit.py \
  tests/2026-07-11_triangular_magsafe_stand_test.sh stl/2026-07-11
git commit -m "Export triangular MagSafe stand print set" \
  -m "Add deterministic CGAL export tooling, binary/ASCII STL topology audits, individual link, gauge, bridge, cassette, lid and spacer files, and visual-only assembled preview artifacts. Verify dated naming, one-shell watertight meshes, positive volumes, collision scenes and three inspected assembly views."
```

### Task 6: Document printing, assembly, and prototype limits

**Files:**
- Modify: `models/iphone_holder/README.md`
- Modify: `docs/superpowers/plans/2026-07-11-triangular-magsafe-link-stand.md`

**Interfaces:**
- Consumes: final dimensions and artifact names from Tasks 1–5.
- Produces: user-facing BOM, print order, assembly order, ballast target, and clear distinction between printable part STL files and the visual-only assembled STL.

- [x] **Step 1: Add the exact BOM and print order**

Document 12 links, one cassette body, one lid, two spacers, one bridge/holder, six 105 mm M4 threaded rods, twelve M4 washers, twelve M4 nuts with at least six nyloc nuts, at least 600 g dry steel ballast, four 12–15 mm rubber feet, and the official MagSafe puck. State that the first print is only `modular_link_fit_pair` plus `magsafe_fit_gauge`.

- [x] **Step 2: Add assembly and use instructions**

Document alternating link faces, three lower rods through the cassette sleeves, two side-midpoint spacers, the keyed apex bridge, gradual cross-pattern tightening, steel filling by scale, foam anti-rattle layer, filament lid pin, and edge-peel phone removal. Mark direct pull unsupported without broad removable table adhesive.

- [x] **Step 3: Run fresh final verification**

Run:

```bash
git diff --check
bash tests/2026-07-11_modular_link_concept_test.sh
bash tests/2026-07-11_triangular_magsafe_stand_test.sh
git status --short
```

Expected: no whitespace errors, both suites PASS, and status contains only the intended README/plan update before the final commit.

- [x] **Step 4: Mark completed plan checkboxes and commit documentation**

```bash
git add models/iphone_holder/README.md \
  docs/superpowers/plans/2026-07-11-triangular-magsafe-link-stand.md
git commit -m "Document MagSafe stand printing and assembly" \
  -m "Add the complete printed and metal hardware BOM, PETG orientations, fit-coupon-first workflow, frame and ballast assembly sequence, 800 g minimum mass target, edge-peel usage limit, artifact map and fresh verification commands. Mark all implementation-plan tasks complete."
```

- [ ] **Step 5: Push after GitHub authentication is restored**

The user disabled subagents, so the final review and verification were performed directly. Both full suites and the artifact checks pass. Push `main` to `origin` after restoring a GitHub-authorized SSH key or HTTPS credential; the current environment returns `Permission denied (publickey)` and has no HTTPS username/token.
