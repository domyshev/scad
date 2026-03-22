module sideFrameGears() {
    // Центральная шестерня
    color(getColor("gear_bronze"))
    translate([0, 0, thickness])
    drawGearByTeeth(12);

    // Средние шестерни
    mirroredGears(20, -3, mid_gear_xy[0], mid_gear_xy[1], getColor("gear_middle_pair"));

    // Нижняя шестерня
    mirroredGears(24, 7, fin_gear_xy[0], fin_gear_xy[1], getColor("gear_bronze"));
}