include <../settings/colors.scad>

function _color_named(name, entries, i = 0) =
    i >= len(entries)
        ? [1, 0, 1, 1]  // unknown key: magenta
        : entries[i][0] == name
            ? entries[i][1]
            : _color_named(name, entries, i + 1);

function getColor(name) = _color_named(name, COLORS);