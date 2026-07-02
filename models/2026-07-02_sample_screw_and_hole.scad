// Тест: болт M10 в отверстии — проверка совместимости
// Пластина 30x30x10 с отверстием по центру, в него вкручен болт

$fn = 128;

use <../lib/core/threads/threads.scad>

// Размеры пластины
plate_w  = 30;
plate_d  = 30;
plate_h  = 10;

// Параметры резьбы (одинаковые для отверстия и болта)
bolt_d     = 10;     // номинальный диаметр (M10)
bolt_pitch = 1.5;    // шаг резьбы
bolt_h     = plate_h;

// Пластина (крышка) — синяя
color("#4a90d9")
difference() {
    cube([plate_w, plate_d, plate_h]);

    // Отверстие с резьбой по центру
    translate([plate_w / 2, plate_d / 2, -0.05])
        metric_thread(diameter = bolt_d, pitch = bolt_pitch, length = bolt_h + 0.1, internal = true);
}

// Болт — серо-стальной, вкручен сверху
color("#6b7b8d")
translate([plate_w / 2, plate_d / 2, plate_h])
    metric_thread(diameter = bolt_d, pitch = bolt_pitch, length = bolt_h, internal = false);