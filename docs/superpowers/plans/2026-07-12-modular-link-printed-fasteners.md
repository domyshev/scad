# Modular Link Printed Fasteners Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the dated SCAD source, export script, tests, and three STL artifacts for a printed bolt, hex nut, and wing nut that fit the 2026-07-11 modular link.

**Architecture:** One OpenSCAD model exposes a `part` selector for `hex_bolt`, `hex_nut`, `wing_nut`, and a visual `assembly_preview`. One shell export script writes the three dated STL files into `stl/2026-07-12/modular_link_fasteners`. One shell test verifies parameters, scene dispatch, mesh validity, bounds, date-prefix naming, nested artifact location, and freshness.

**Tech Stack:** OpenSCAD, `lib/core/threads/threads.scad`, Bash, Python STL mesh audit, `jq`.

## Global Constraints

- Do not use subagents for this implementation.
- Work on the current branch because the user explicitly requested commit and push from this project.
- Commit messages must include a subject and detailed body.
- Every STL under `stl/2026-07-12/` must start with `2026-07-12_`.
- Artifacts must be stored under `stl/2026-07-12/modular_link_fasteners/`.
- Bolt shaft nominal outer diameter: `4.2 mm`.
- Nut thread cut diameter: `4.65 mm`.
- Pitch: `1.0 mm`.
- Bolt under-head length: `19.0 mm`.
- Smooth shank length: `12.0 mm`.
- Threaded length: `7.0 mm`.
- Hex head: `8.0 mm` across flats, `3.6 mm` tall.
- Hex nut: `8.0 mm` across flats, `4.5 mm` tall.
- Wing nut: `28.0 mm` wingspan, `4.8 mm` tall.

---

### Task 1: Fastener Source, Export, and Artifacts

**Files:**
- Create: `tests/2026-07-12_modular_link_printed_fasteners_test.sh`
- Create: `models/iphone_holder/2026-07-12_modular_link_printed_fasteners.scad`
- Create: `scripts/2026-07-12_export_modular_link_fasteners.sh`
- Create: `stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_hex_bolt.stl`
- Create: `stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_hex_nut.stl`
- Create: `stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_wing_nut.stl`

**Interfaces:**
- Consumes: existing `lib/core/threads/threads.scad` module `metric_thread(...)`.
- Consumes: existing mesh auditor `tests/2026-07-11_stl_mesh_audit.py`.
- Produces: OpenSCAD variable `part` with values `hex_bolt`, `hex_nut`, `wing_nut`, `assembly_preview`.
- Produces: export script that accepts an optional output directory and defaults to `stl/2026-07-12/modular_link_fasteners`.

- [ ] **Step 1: Write the failing test**

Create `tests/2026-07-12_modular_link_printed_fasteners_test.sh` with checks that:

```bash
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_printed_fasteners.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_fasteners.sh"
artifact_root="$repo_root/stl/2026-07-12/modular_link_fasteners"
date_prefix="2026-07-12"
```

The test must fail while the source, script, and artifacts are absent. It must later render each part with OpenSCAD, check `parameter_echo`, verify expected bounding boxes, audit each STL as one watertight component, run the export script to a temp directory, and compare fresh temp output against stored artifacts.

- [ ] **Step 2: Run test to verify it fails**

Run: `tests/2026-07-12_modular_link_printed_fasteners_test.sh`

Expected: `FAIL: missing printed fastener source`.

- [ ] **Step 3: Write minimal model and export script**

Create `models/iphone_holder/2026-07-12_modular_link_printed_fasteners.scad` with:

```openscad
use <../../lib/core/threads/threads.scad>
part = "assembly_preview";
bolt_outer_d = 4.2;
thread_pitch = 1.0;
thread_size = 0.65;
nut_thread_cut_d = 4.65;
```

Create modules `hex_bolt()`, `hex_nut()`, and `wing_nut()` using the spec dimensions and dispatch by `part`.

Create `scripts/2026-07-12_export_modular_link_fasteners.sh` that exports exactly:

```text
2026-07-12_modular_link_hex_bolt.stl
2026-07-12_modular_link_hex_nut.stl
2026-07-12_modular_link_wing_nut.stl
```

- [ ] **Step 4: Export stored artifacts**

Run: `scripts/2026-07-12_export_modular_link_fasteners.sh`

Expected: all three STL files are written under `stl/2026-07-12/modular_link_fasteners/`.

- [ ] **Step 5: Run test to verify it passes**

Run: `tests/2026-07-12_modular_link_printed_fasteners_test.sh`

Expected: `PASS: modular-link printed fasteners are valid`.

- [ ] **Step 6: Run final verification**

Run:

```bash
tests/2026-07-12_modular_link_printed_fasteners_test.sh
git diff --check
git status --short --branch
```

Expected: test passes, diff check passes, status shows only intended files before commit.

- [ ] **Step 7: Commit and push**

Run:

```bash
git add docs/superpowers/plans/2026-07-12-modular-link-printed-fasteners.md \
    tests/2026-07-12_modular_link_printed_fasteners_test.sh \
    models/iphone_holder/2026-07-12_modular_link_printed_fasteners.scad \
    scripts/2026-07-12_export_modular_link_fasteners.sh \
    stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_hex_bolt.stl \
    stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_hex_nut.stl \
    stl/2026-07-12/modular_link_fasteners/2026-07-12_modular_link_wing_nut.stl
git commit
git push
```

Commit body must include files, dimensions, generated artifacts, and verification commands.
