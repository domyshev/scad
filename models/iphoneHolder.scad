// iPhone Holder — стенд-база
// Внешние размеры: 140 x 100 x 20 мм
// Толщина стенок: 5 мм
// Внутри полый (открытый сверху)

// Модуль внутренней резьбы (метрическая)
module threaded_hole(d = 10, pitch = 1.5, h = 5) {
    $fn = max($fn, 48);

    D = d;
    P = pitch;
    D1 = D - 1.082532 * P;

    difference() {
        cylinder(d = D, h = h + 0.05);

        translate([0, 0, -P/2])
        linear_extrude(
            height = h + P,
            twist = -360 * (h + P) / P,
            slices = ceil((h + P) / P * 24),
            convexity = 5
        )
        polygon(points = [
            [D1/2 - 0.05, -P/2],
            [D/2 + 0.05, -P/4],
            [D/2 + 0.05,  P/4],
            [D1/2 - 0.05,  P/2]
        ]);
    }
}

// Модуль внешней резьбы (метрическая)
module external_thread(d = 10, pitch = 1.5, h = 10) {
    $fn = max($fn, 48);

    D = d;
    P = pitch;
    D1 = D - 1.082532 * P;

    union() {
        // Стержень по внутреннему диаметру резьбы
        cylinder(d = D1, h = h);

        // Спиральные выступы резьбы
        translate([0, 0, -P/2])
        linear_extrude(
            height = h + P,
            twist = 360 * (h + P) / P,
            slices = ceil((h + P) / P * 24),
            convexity = 5
        )
        polygon(points = [
            [D1/2, -P/2],
            [D/2 + 0.05, -P/4],
            [D/2 + 0.05,  P/4],
            [D1/2,  P/2]
        ]);
    }
}

// Винт-потай M10 со шлицем под плоскую отвертку
module countersunk_screw(d = 10, pitch = 1.5, thread_h = lid_h) {
    Dk = 18;    // диаметр головки
    K  = 4;     // высота головки

    slot_w = 2;   // ширина шлица
    slot_d = 2;   // глубина шлица

    union() {
        // Резьбовая часть (входит в отверстие крышки)
        translate([0, 0, -thread_h])
            external_thread(d = d, pitch = pitch, h = thread_h);

        // Головка-потай — конус от Dk до d
        difference() {
            cylinder(d1 = Dk, d2 = d, h = K);

            // Шлиц под плоскую отвертку
            translate([0, 0, K - slot_d])
                cube([Dk - 4, slot_w, slot_d + 0.1], center = true);
        }
    }
}

$fn = 128;

// Толщина стенок
wall = 5;

// внешний параллелипипед
inner_h = 20;
	
// Наружный параллелепипед
outer_w = 140;
outer_d = 100;
outer_h = inner_h + wall;

// Толщина крышки
lid_h = 10 * 1;

// Зазор ребер от стенок (для перелива воды)
gap = 10;

// Высота ребер (от дна до верха полости)
rib_h = inner_h;

// Основной корпус
color("#4a90d9")
difference() {
    // Внешняя форма
    cube([outer_w, outer_d, outer_h]);

    // Внутренняя полость (открыта сверху)
    translate([wall, wall, wall])
        cube([
            outer_w - 2 * wall,
            outer_d - 2 * wall,
            outer_h - wall + 1  // стенка снизу 5мм, сверху открыто
        ]);
}

// Рёбра жесткости — контрастный цвет, с зазором от стенок для перелива воды
color("#f5a623")
union() {
    // Ребро вдоль X (посередине Y)
    translate([wall + gap, outer_d / 2, wall])
        cube([outer_w - 2 * wall - 2 * gap, wall, rib_h]);

    // Ребро вдоль Y (посередине X)
    translate([outer_w / 2, wall + gap, wall])
        cube([wall, outer_d - 2 * wall - 2 * gap, rib_h]);
}

// Крышка сверху — другой цвет, с отверстием и резьбой M10
color("#e85d3a")
difference() {
    // Основание крышки
    translate([0, 0, outer_h])
        cube([outer_w, outer_d, lid_h]);

    // Отверстие с резьбой — центр по длинной стороне, 15 мм от края
    translate([outer_w / 2, 15, outer_h - 0.05])
        threaded_hole(d = 10, pitch = 1.5, h = lid_h + 0.1);
}

// Винт-потай M10 — вкручен в отверстие
color("#6b7b8d")  // серо-стальной
translate([outer_w / 2, 15, outer_h + lid_h])
    countersunk_screw(d = 10, pitch = 1.5, thread_h = lid_h);
