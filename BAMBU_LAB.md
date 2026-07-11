# Bambu Lab A1 mini PETG strength notes

## File naming

`BAMBU_LAB.md` is a normal Markdown filename. An underscore is safe to use in
Markdown file names.

## Goal

These settings are intended for strong PETG prints on Bambu Lab A1 mini,
especially for functional parts such as the sealed base box, brackets, bolts,
and threaded parts.

The main idea is not to rely only on 100% infill. For many functional parts,
strength improves more predictably from more wall loops, enough top and bottom
shells, slower PETG speeds, and good layer bonding.

## Strong base box profile

For the hollow box/base:

```text
Wall loops:              8
Top shell layers:        9
Bottom shell layers:     9
Sparse infill density:   60%
Sparse infill pattern:   Gyroid or Cubic
```

This is already a very strong profile. 100% infill for the whole box is usually
not the first choice because it greatly increases print time, material use,
internal stress, and possible warping.

## Small high-load parts

For bolts, threaded parts, and bracket parts that receive tightening force:

```text
Wall loops:              8
Top shell layers:        7-9
Bottom shell layers:     7-9
Sparse infill density:   80-100%
Sparse infill pattern:   Gyroid or Cubic
```

For small bolts, 100% infill is reasonable.

## Speed settings

In Bambu Studio, if the speed section is shown as `Other layers speed`, set the
main print speeds there.

Conservative PETG settings:

```text
Outer wall:              40 mm/s
Inner wall:              60 mm/s
Sparse infill:           70 mm/s
Internal solid infill:   60 mm/s
Top surface:             35 mm/s
Gap infill:              35 mm/s
Bridge:                  25 mm/s
```

If there is a separate first layer speed setting, it can usually stay at the
default when adhesion is already good. If first-layer adhesion is unreliable,
slow the first layer down.

## Acceleration

If acceleration settings are visible, use calmer values for PETG:

```text
Outer wall acceleration:  1000-1500 mm/s^2
Inner wall acceleration:  2000 mm/s^2
Infill acceleration:      2500-3000 mm/s^2
First layer acceleration: 500 mm/s^2
```

Travel acceleration can usually stay at the default.

## Filament flow limit

In filament settings, limit PETG flow:

```text
Max volumetric speed:     8 mm^3/s
```

This helps avoid pushing PETG faster than it can melt and bond well. Better
layer bonding is important for strong functional parts.

## Print mode

Use:

```text
Print mode: Standard or Silent
```

Avoid:

```text
Sport
Ludicrous
```

Fast modes are not recommended when the goal is maximum PETG strength and
reliable layer bonding.

## Practical notes

- Dry PETG before important prints.
- More walls often improve strength more reliably than simply increasing infill.
- For the sealed base box, the current strong starting point is `8 / 9 / 9 / 60%`.
- For bolts and other small loaded parts, use higher infill, up to 100%.
- Print orientation matters: parts are usually weakest between layers.
