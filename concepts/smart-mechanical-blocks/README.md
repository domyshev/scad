# Smart Mechanical Blocks Concept

This folder contains a standalone visual concept board for a mechanical
household construction system: printable rectangular blocks that connect through
locks, rails, wedges, threads, detents, and gear-friendly interfaces.

## Files

- `index.html` - interactive static concept board with four mechanical kernels
  and ten lock/interface options.

## Open Directly

From the repository root:

```bash
open concepts/smart-mechanical-blocks/index.html
```

## Run With A Local Server

This is useful if the browser blocks local-file behavior or if you want a stable
localhost URL:

```bash
python3 -m http.server 8123 --directory concepts/smart-mechanical-blocks
```

Then open:

```text
http://localhost:8123/
```

## Current Recommendation

The strongest first prototype direction is:

- `1. Ласточкин хвост` for the main load-bearing block-to-block slide.
- `4. Клин-шпонка` to remove print-tolerance play after assembly.
- `10. Зубчатая рейка` to connect the block language to future gears and moving
  shelf mechanisms.
