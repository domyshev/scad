# M8 Modular Link Fasteners Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a printed hex bolt and hex nut for the 2026-07-12 M8 modular link, exporting both STL files into the existing `modular_link_m8` artifact folder.

**Architecture:** Create one OpenSCAD source with a `part` selector for `hex_bolt`, `hex_nut`, and `assembly_preview`. A dedicated export script writes both dated STL files to `stl/2026-07-12/modular_link_m8`. A shell test verifies dimensions, mesh validity, date-prefix naming, folder placement, and fresh-export mesh matching.

**Tech Stack:** OpenSCAD, `lib/core/threads/threads.scad`, Bash, `jq`, existing Python STL mesh auditor.

## Global Constraints

- Do not use subagents.
- Do not modify existing M8 link source or STL.
- Export fastener STL artifacts into `stl/2026-07-12/modular_link_m8/`.
- Every STL filename under `stl/2026-07-12/` must start with `2026-07-12_`.
- Bolt outer diameter: `8.4 mm`.
- Link clearance hole: `8.8 mm`.
- Nut thread cut diameter: `9.0 mm`.
- Thread pitch: `1.5 mm`.
- Thread size: `1.0 mm`.
- Bolt under-head length: `26 mm`.
- Smooth shank length: `13 mm`.
- Threaded length: `13 mm`.
- Hex head: `13 mm` across flats, `5.5 mm` tall.
- Hex nut: `13 mm` across flats, `7 mm` tall.

---

### Task 1: M8 Fastener Source, Export, and Artifacts

**Files:**
- Create: `tests/2026-07-12_modular_link_m8_fasteners_test.sh`
- Create: `models/iphone_holder/2026-07-12_modular_link_m8_fasteners.scad`
- Create: `scripts/2026-07-12_export_modular_link_m8_fasteners.sh`
- Create: `stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_m8_hex_bolt.stl`
- Create: `stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_m8_hex_nut.stl`

**Interfaces:**
- Consumes: `lib/core/threads/threads.scad` module `metric_thread(...)`.
- Consumes: `tests/2026-07-11_stl_mesh_audit.py`.
- Produces: OpenSCAD variable `part` with values `hex_bolt`, `hex_nut`, and `assembly_preview`.
- Produces: export script with optional output directory and default `stl/2026-07-12/modular_link_m8`.

- [ ] **Step 1: Write the failing test**

Create `tests/2026-07-12_modular_link_m8_fasteners_test.sh` that checks:

```bash
source_model="$repo_root/models/iphone_holder/2026-07-12_modular_link_m8_fasteners.scad"
export_script="$repo_root/scripts/2026-07-12_export_modular_link_m8_fasteners.sh"
artifact_root="$repo_root/stl/2026-07-12/modular_link_m8"
date_prefix="2026-07-12"
```

The test must render `hex_bolt` and `hex_nut`, check parameter echo, verify expected bounding boxes, audit each STL as one watertight component, verify both artifacts in the existing M8 folder with date prefixes, run a fresh export to a temp directory, and compare fresh meshes against stored artifacts.

- [ ] **Step 2: Run the failing test**

Run: `tests/2026-07-12_modular_link_m8_fasteners_test.sh`

Expected: `FAIL: missing M8 fastener source`.

- [ ] **Step 3: Create the model and export script**

Create `models/iphone_holder/2026-07-12_modular_link_m8_fasteners.scad` with:

```openscad
bolt_outer_d = 8.4;
link_bolt_clearance_d = 8.8;
thread_pitch = 1.5;
thread_size = 1.0;
nut_thread_cut_d = 9.0;
bolt_head_af = 13;
bolt_head_h = 5.5;
bolt_under_head_len = 26;
bolt_smooth_len = 13;
bolt_thread_len = 13;
hex_nut_af = 13;
hex_nut_h = 7;
```

Create `scripts/2026-07-12_export_modular_link_m8_fasteners.sh` that exports:

```text
2026-07-12_modular_link_m8_hex_bolt.stl
2026-07-12_modular_link_m8_hex_nut.stl
```

- [ ] **Step 4: Export stored artifacts**

Run: `scripts/2026-07-12_export_modular_link_m8_fasteners.sh`

Expected: both STL files are written into `stl/2026-07-12/modular_link_m8/`.

- [ ] **Step 5: Run verification**

Run:

```bash
tests/2026-07-12_modular_link_m8_fasteners_test.sh
git diff --check
git status --short --branch
```

Expected: test passes, diff check passes, and status shows only intended M8 fastener files before commit.

- [ ] **Step 6: Commit and push**

Run:

```bash
git add docs/superpowers/plans/2026-07-12-modular-link-m8-fasteners.md \
    tests/2026-07-12_modular_link_m8_fasteners_test.sh \
    models/iphone_holder/2026-07-12_modular_link_m8_fasteners.scad \
    scripts/2026-07-12_export_modular_link_m8_fasteners.sh \
    stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_m8_hex_bolt.stl \
    stl/2026-07-12/modular_link_m8/2026-07-12_modular_link_m8_hex_nut.stl
git commit
git push
```

Commit body must mention the M8 fastener dimensions, generated STL paths, and verification commands.
