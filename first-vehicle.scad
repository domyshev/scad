// --- Настройки ---
$fn = 60;
thickness = 8;
hole_d = 4.9; 
pitch = 8; 
gear_dist = pitch * 3; 
wheel_dist = pitch * 6; 

my_body_color = [119/255, 136/255, 153/255, 0.9];
my_cutter_color = [1, 0, 0, 0.5];

// --- Вспомогательные модули ---
module hole() {
    cylinder(d = hole_d, h = thickness + 2, center = true);
}

// --- ОСНОВНОЙ МОДУЛЬ ДЕТАЛИ ---
module side_plate() {
    difference() {
        color(my_body_color)
        union() {
            // "Плечи" к колесам
            hull() {
                cylinder(d = 30, h = thickness, center = true);
                translate([-wheel_dist, -pitch*2, 0]) 
                    cylinder(d = 16, h = thickness, center = true);
                translate([wheel_dist, -pitch*2, 0])  
                    cylinder(d = 16, h = thickness, center = true);
            }
        }
        
        // Вырез нижней дуги
        color(my_cutter_color)   
        translate([0, -125, 0])
            cylinder(d = 225, h = thickness + 2, center = true);

        // ОТВЕРСТИЯ
        color(my_cutter_color) {
            // Центр (Вал мотора)
            hole();

            // Крепление мотора (квадрат 16x16мм)
            for (pos = [[pitch, 0], [-pitch, 0], [0, pitch], [0, -pitch]]) {
                translate([pos[0], pos[1], 0]) hole();
            }

            // Промежуточные шестерни и оси колес
            for (s = [-1, 1]) {
                translate([s * gear_dist, -pitch, 0]) hole();
                translate([s * wheel_dist, -pitch*2, 0]) hole();
            }

            // Крепления для поперечных балок
            translate([-wheel_dist/2, 10, 0]) hole();
            translate([wheel_dist/2, 10, 0])  hole();
        }
    }
}

// --- ШТАМПУЕМ ДЕТАЛИ ---

// Первая боковина
side_plate();

// Вторая боковина (сдвигаем по оси Z, чтобы стояли друг против друга)
// 40мм - это примерное расстояние между боковинами под ширину твоего мотора
translate([0, 0, 16]) 
    side_plate();