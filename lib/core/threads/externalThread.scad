// Внешняя резьба — стержень / цилиндр болта
//
// Параметры:
//   d         — номинальный диаметр резьбы (мм)
//   pitch     — шаг резьбы (мм)
//   h         — длина резьбовой части (мм)
//   thickness — диаметр «проволоки» резьбы (мм)
//
// В комплекте с internalThread() при одинаковых d, pitch, thickness
// болт плотно входит в отверстие.

module externalThread(d = 10, pitch = 1.5, h = 10, thickness = 1.5) {
    $fn = max($fn, 48);
    clear = 0.05;

    r_center = (d - thickness) / 2;   // центр проволоки
    core_d   = d - thickness;         // диаметр стержня

    union() {
        // Стержень
        cylinder(d = core_d - clear, h = h);

        // Спиральная «проволока»
        translate([0, 0, -pitch/2])
        linear_extrude(
            height = h + pitch,
            twist = 360 * (h + pitch) / pitch,
            slices = ceil((h + pitch) / pitch * 36),
            convexity = 5
        )
        translate([r_center, 0])
            circle(d = thickness - clear);
    }
}