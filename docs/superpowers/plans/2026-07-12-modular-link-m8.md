# M8 Modular Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single 7.5-degree modular-link STL variant sized for M8 hardware.

**Architecture:** Create a new OpenSCAD model by reusing the fine-index link structure with larger joint geometry: 24 mm joint pads, 8.8 mm bolt clearance, and a 12-22 mm serration ring. A dedicated export script writes one dated STL into `stl/2026-07-12/modular_link_m8`. A shell test verifies dimensions, accepted/rejected angles, mesh validity, date-prefix naming, and fresh-export artifact matching.

**Tech Stack:** OpenSCAD, Bash, `jq`, existing Python STL mesh auditor.

## Global Constraints

- Do not use subagents.
- Do not modify existing M4/fine-index link models.
- Export only a single-link STL.
- STL artifacts must be under `stl/2026-07-12/modular_link_m8/`.
- Every STL filename under `stl/2026-07-12/` must start with `2026-07-12_`.
- Working tooth count: `48`.
- Angle step: `7.5°`.
- Link pitch: `40 mm`.
- Joint pad diameter: `24 mm`.
- Body thickness: `6 mm`.
- M8 bolt clearance: `8.8 mm`.
- Serration inner diameter: `12 mm`.
- Serration outer diameter: `22 mm`.
- Tooth height: `0.7 mm`.
- Tooth valley height: `0.1 mm`.
- Tooth embed: `0.2 mm`.

---

### Task 1: M8 Single Link Source, Export, and Artifact

**Files:**
- Create: `tests/2026-07-12_modular_link_m8_test.sh`
- Create: `models/iphone_holder/2026-07-12_modular_link_m8.scad`
- Create: `scripts/2026-07-12_export_modular_link_m8.sh`
- Create: `stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_7_5deg_m8.stl`

**Interfaces:**
- Consumes: `tests/2026-07-11_stl_mesh_audit.py`.
- Produces: OpenSCAD variable `scene` with values `single_link`, `assembled_joint`, `exploded_joint`, `joint_overlap`, and `presentation`.
- Produces: export script with optional output directory and default `stl/2026-07-12/modular_link_m8`.

- [ ] **Step 1: Write the failing test**

Create `tests/2026-07-12_modular_link_m8_test.sh` that checks:

```bash
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_m8.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_m8.sh"
artifact_root="$repo_root/stl/2026-07-12/modular_link_m8"
date_prefix="2026-07-12"
```

The test must render accepted angles `0 7.5 15 30 45 90 135 180`, reject `11.25`, verify a single-link bounding box near `64 x 24 x 6.7 mm`, audit the single STL as one component, verify the dated artifact path, run a fresh export to a temp directory, and compare fresh mesh against the stored artifact.

- [ ] **Step 2: Run the failing test**

Run: `tests/2026-07-12_modular_link_m8_test.sh`

Expected: `FAIL: missing M8 modular-link source`.

- [ ] **Step 3: Create the model and export script**

Create `models/iphone_holder/2026-07-12_modular_link_m8.scad` with:

```openscad
joint_d = 24;
bolt_clearance_d = 8.8;
tooth_inner_d = 12;
tooth_outer_d = 22;
tooth_count = 48;
tooth_pitch_angle = 360 / tooth_count;
supported_joint_angle_max = 180;
```

Create `scripts/2026-07-12_export_modular_link_m8.sh` that exports:

```text
2026-07-12_modular_link_7_5deg_m8.stl
```

- [ ] **Step 4: Export stored artifact**

Run: `scripts/2026-07-12_export_modular_link_m8.sh`

Expected: the STL file is written into `stl/2026-07-12/modular_link_m8/`.

- [ ] **Step 5: Run verification**

Run:

```bash
tests/2026-07-12_modular_link_m8_test.sh
git diff --check
git status --short --branch
```

Expected: test passes, diff check passes, and status shows only the intended M8 files before commit.

- [ ] **Step 6: Commit and push**

Run:

```bash
git add docs/superpowers/plans/2026-07-12-modular-link-m8.md \
    tests/2026-07-12_modular_link_m8_test.sh \
    models/iphone_holder/2026-07-12_modular_link_m8.scad \
    scripts/2026-07-12_export_modular_link_m8.sh \
    stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_7_5deg_m8.stl
git commit
git push
```

Commit body must mention the M8 clearance, enlarged joint geometry, generated STL path, and verification commands.
