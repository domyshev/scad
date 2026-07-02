// Тест: болт M10 в отверстии — проверка совместимости
// Пластина 30x30x10 с отверстием по центру, в него вкручен болт

$fn = 128;

use <../lib/core/threads/internalThread.scad>
use <../lib/core/threads/externalThread.scad>

// Размеры пластины
plate_w  = 30;
plate_d  = 30;
plate_h  = 10;

// Параметры резьбы (одинаковые для отверстия и болта)
bolt_d     = 10;
bolt_pitch = 1.5;
bolt_h     = plate_h;
bolt_depth = 1.2;

// Смещение болта по Z: верхняя грань пластины
z_offset = plate_h;

// Пластина (крышка) — синяя
color("#4a90d9")
difference() {
    cube([plate_w, plate_d, plate_h]);

    // Отверстие с резьбой по центру
    translate([plate_w / 2, plate_d / 2, -0.05])
        internalThread(d = bolt_d, pitch = bolt_pitch, h = bolt_h + 0.1, depth = bolt_depth);
}

// Болт — серо-стальной, вкручен сверху
color("#6b7b8d")
translate([plate_w / 2, plate_d / 2, z_offset])
    externalThread(d = bolt_d, pitch = bolt_pitch, h = bolt_h, depth = bolt_depth);
