# Fine-Index Modular Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 2026-07-12 modular-link variant with 7.5-degree indexed serrations and dated STL artifacts in a separate today's-folder subdirectory.

**Architecture:** Copy the proven 2026-07-11 modular-link OpenSCAD structure into a new source file and change only the indexed serration parameters/range needed for 7.5-degree positioning. A dedicated export script writes the single link and a two-link fit-pair to `stl/2026-07-12/modular_link_fine_index`. A shell test verifies the accepted/rejected angles, mesh validity, bounds, file naming, and fresh-export artifact match.

**Tech Stack:** OpenSCAD, Bash, `jq`, existing Python STL mesh auditor.

## Global Constraints

- Do not use subagents.
- Do not modify `models/iphone_holder/2026-07-11_modular_link_concept.scad`.
- STL artifacts must be under `stl/2026-07-12/modular_link_fine_index/`.
- Every STL filename under `stl/2026-07-12/` must start with `2026-07-12_`.
- New working tooth count: `48`.
- New angle step: `7.5°`.
- Supported angles must include `0`, `7.5`, `15`, `30`, `45`, `90`, `135`, and `180`.
- Non-indexed angle `11.25°` must be rejected.
- Retain link pitch `40 mm`, joint diameter `20 mm`, body thickness `6 mm`, bolt clearance `4.6 mm`, serration inner diameter `10 mm`, serration outer diameter `18 mm`, tooth height `0.7 mm`, valley height `0.1 mm`, and tooth embed `0.2 mm`.

---

### Task 1: Fine-Index Link Source, Export, and Artifacts

**Files:**
- Create: `tests/2026-07-12_modular_link_fine_index_test.sh`
- Create: `models/iphone_holder/2026-07-12_modular_link_fine_index.scad`
- Create: `scripts/2026-07-12_export_modular_link_fine_index.sh`
- Create: `stl/2026-07-12/modular_link_fine_index/2026-07-12_modular_link_7_5deg.stl`
- Create: `stl/2026-07-12/modular_link_fine_index/2026-07-12_modular_link_7_5deg_fit_pair.stl`

**Interfaces:**
- Consumes: `tests/2026-07-11_stl_mesh_audit.py`.
- Produces: OpenSCAD variable `scene` with values `single_link`, `fit_pair_print`, `assembled_joint`, `exploded_joint`, `joint_overlap`, and `presentation`.
- Produces: functions `modular_link_fine_index_step_angle()` and `modular_link_fine_index_tooth_count()` for testable parameter echo and future reuse.
- Produces: export script with optional output directory and default `stl/2026-07-12/modular_link_fine_index`.

- [ ] **Step 1: Write the failing test**

Create `tests/2026-07-12_modular_link_fine_index_test.sh` that checks:

```bash
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_fine_index.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_fine_index.sh"
artifact_root="$repo_root/stl/2026-07-12/modular_link_fine_index"
date_prefix="2026-07-12"
```

The test must render accepted angles `0 7.5 15 30 45 90 135 180`, reject `11.25`, audit `single_link` as one component, audit `fit_pair_print` as two components, verify dated artifact names, run a fresh export to a temp directory, and compare fresh meshes against stored artifacts.

- [ ] **Step 2: Run the failing test**

Run: `tests/2026-07-12_modular_link_fine_index_test.sh`

Expected: `FAIL: missing fine-index modular-link source`.

- [ ] **Step 3: Create the model and export script**

Create `models/iphone_holder/2026-07-12_modular_link_fine_index.scad` by carrying over the existing modular-link structure and setting:

```openscad
tooth_count = 48;
tooth_pitch_angle = 360 / tooth_count;
serration_station_count = 2 * tooth_count;
supported_joint_angle_max = 180;
```

Create `scripts/2026-07-12_export_modular_link_fine_index.sh` that exports:

```text
2026-07-12_modular_link_7_5deg.stl
2026-07-12_modular_link_7_5deg_fit_pair.stl
```

- [ ] **Step 4: Export stored artifacts**

Run: `scripts/2026-07-12_export_modular_link_fine_index.sh`

Expected: both STL files are written into `stl/2026-07-12/modular_link_fine_index/`.

- [ ] **Step 5: Run verification**

Run:

```bash
tests/2026-07-12_modular_link_fine_index_test.sh
git diff --check
git status --short --branch
```

Expected: test passes, diff check passes, and status shows only the intended fine-index files before commit.

- [ ] **Step 6: Commit**

Run:

```bash
git add docs/superpowers/plans/2026-07-12-modular-link-fine-index.md \
    tests/2026-07-12_modular_link_fine_index_test.sh \
    models/iphone_holder/2026-07-12_modular_link_fine_index.scad \
    scripts/2026-07-12_export_modular_link_fine_index.sh \
    stl/2026-07-12/modular_link_fine_index/2026-07-12_modular_link_7_5deg.stl \
    stl/2026-07-12/modular_link_fine_index/2026-07-12_modular_link_7_5deg_fit_pair.stl
git commit
```

Commit body must mention the 48-tooth / 7.5-degree indexing, generated STL paths, and verification commands.
