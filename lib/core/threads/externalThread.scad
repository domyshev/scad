// Внешняя резьба — стержень / цилиндр болта
//
// Параметры:
//   d     — номинальный диаметр резьбы (мм)
//   pitch — шаг резьбы (мм)
//   h     — длина резьбовой части (мм)
//   depth — глубина / толщина выступа резьбы (мм)
//
// В комплекте с internalThread() при одинаковых d, pitch, depth
// болт плотно входит в отверстие.

module externalThread(d = 10, pitch = 1.5, h = 10, depth = 1.2) {
    $fn = max($fn, 48);

    inner_r = d/2 - depth;
    outer_r = d/2;

    union() {
        // Стержень по внутреннему диаметру
        cylinder(d = 2 * inner_r, h = h);

        // Спиральные выступы резьбы
        translate([0, 0, -pitch/2])
        linear_extrude(
            height = h + pitch,
            twist = 360 * (h + pitch) / pitch,
            slices = ceil((h + pitch) / pitch * 24),
            convexity = 5
        )
        polygon(points = [
            [inner_r, -pitch/2],
            [outer_r + 0.05, -pitch/4],
            [outer_r + 0.05,  pitch/4],
            [inner_r,  pitch/2]
        ]);
    }
}