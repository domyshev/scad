// Тест: болт M10 в отверстии — проверка совместимости
// Пластина 20x20x10 с отверстием по центру, в него вкручен болт

$fn = 64;
preview_fast = $preview;

// Переключатели деталей для отдельного экспорта в STL.
show_plate = true;
show_bolt = true;

use <../lib/core/threads/threads.scad>

// Размеры пластины
plate_w  = 20;
plate_d  = 20;
plate_h  = 10;

// Параметры резьбы (одинаковые для отверстия и болта)
bolt_d     = 10;     // номинальный диаметр (M10)
bolt_pitch = 1.5;    // шаг резьбы
bolt_h     = plate_h;

// FDM/PETG needs extra clearance for printed threads.
thread_fit_clearance = 0.4; // added to the internal thread diameter
thread_leadin        = 2;   // chamfer both ends so the thread can start cleanly

// Крестовая канавка сверху болта под отвертку.
driver_slot_enabled = true;
driver_slot_length  = bolt_d * 0.8;
driver_slot_width   = 1.8;
driver_slot_depth   = 1.2;

module cross_driver_slot(length, width, depth, z_top) {
    for (angle = [0, 90]) {
        rotate([0, 0, angle])
            translate([0, 0, z_top - depth / 2 + 0.05])
                cube([length, width, depth + 0.1], center = true);
    }
}

// Пластина (крышка) — синяя
if (show_plate) {
    color("#4a90d9")
    difference() {
        cube([plate_w, plate_d, plate_h]);

        // Отверстие с резьбой по центру
        translate([plate_w / 2, plate_d / 2, -0.05])
            metric_thread(
                diameter = bolt_d + thread_fit_clearance,
                pitch = bolt_pitch,
                length = bolt_h + 0.1,
                internal = true,
                leadin = thread_leadin,
                test = preview_fast
            );
    }
}

// Болт — серо-стальной, вкручен сверху
if (show_bolt) {
    color("#6b7b8d")
    translate([plate_w / 2, plate_d / 2, plate_h])
        difference() {
            metric_thread(
                diameter = bolt_d,
                pitch = bolt_pitch,
                length = bolt_h,
                internal = false,
                leadin = thread_leadin,
                test = preview_fast
            );

            if (driver_slot_enabled) {
                cross_driver_slot(
                    length = driver_slot_length,
                    width = driver_slot_width,
                    depth = driver_slot_depth,
                    z_top = bolt_h
                );
            }
        }
}
