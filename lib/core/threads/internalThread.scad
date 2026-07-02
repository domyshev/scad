// Внутренняя резьба — отверстие под винт/болт
//
// Параметры:
//   d     — номинальный диаметр резьбы (мм)
//   pitch — шаг резьбы (мм)
//   h     — глубина отверстия (мм)
//   depth — глубина / толщина выступа резьбы (мм, по радиусу)
//   land  — доля шага, занятая выступом резьбы (0..1, по умолч. 0.65)
//           чем больше — тем толще бороздка, меньше впадина
//
// В комплекте с externalThread() при одинаковых d, pitch, depth, land
// болт плотно входит в отверстие.

module internalThread(d = 10, pitch = 1.5, h = 10, depth = 1.2, land = 0.65) {
    $fn = max($fn, 48);

    clear = 0.05;         // зазор для свободного хода
    inner_r = d/2 - depth;
    outer_r = d/2;
    half_w = land * pitch / 2;   // полуширина бороздки

    difference() {
        cylinder(d = d, h = h + clear);

        translate([0, 0, -pitch/2])
        linear_extrude(
            height = h + pitch,
            twist = -360 * (h + pitch) / pitch,
            slices = ceil((h + pitch) / pitch * 24),
            convexity = 5
        )
        polygon(points = [
            [inner_r - clear, -half_w],
            [outer_r + clear, -half_w],
            [outer_r + clear,  half_w],
            [inner_r - clear,  half_w]
        ]);
    }
}