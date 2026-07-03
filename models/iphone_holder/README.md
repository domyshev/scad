# iPhone holder box

Папка содержит модель полого бокса под габариты iPhone 15 Pro Max и заметки по
проверенным решениям для печати.

## Габариты

Внешние размеры бокса основаны на iPhone 15 Pro Max:

```text
длина:  159.9 мм  // Apple Height
ширина:  76.7 мм  // Apple Width
высота:  16.5 мм  // две толщины iPhone 15 Pro Max, 8.25 * 2
```

Толщина стенок:

```scad
wall = 4;
```

## Детали и флаги

OpenSCAD 2021 не имеет полноценного синтаксиса объекта/dictionary, поэтому в
модели используется список пар `ключ -> true/false`. Например, так можно
включить все детали:

```scad
parts = [
    ["bottom", true],
    ["top",    true],
    ["front",  true],
    ["back",   true],
    ["left",   true],
    ["right",  true],
    ["rib",    true],
    ["bolt_left_of_rib",  true],
    ["bolt_right_of_rib", true]
];
```

Так можно отключать стенки, внутреннее ребро и оба болта отдельно.

## Ребро и прорезь

В центре бокса есть одно внутреннее ребро:

```text
толщина: 4 мм
направление: параллельно коротким торцевым стенкам
позиция: по центру длины бокса
```

В центре ребра сделана прорезь для сообщения камер:

```scad
rib_slot_enabled = true;
rib_slot_width = 10;
```

Внутренняя высота ребра `8.5 мм`, поэтому размер `10 мм` используется как
ширина прорези, а вырез идет насквозь через доступную высоту ребра.

## Проверенная резьба

Резьба взята из реального теста `2026-07-02_sample_screw_and_hole.scad`, где
после печати хорошо заработало такое соотношение:

```scad
bolt_d = 10;
bolt_pitch = 1.5;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
thread_leadin = 2;
```

Итоговые диаметры:

```text
внутренняя резьба: 10.4 мм
наружная резьба:    9.8 мм
разница:            0.6 мм по диаметру
```

В крышке два резьбовых отверстия с внутренней резьбой `10.4 мм`. Болты имеют
наружную резьбу `9.8 мм`.

## Расположение отверстий в крышке

Отверстия находятся:

```text
5 мм от внутренней грани длинной передней стенки до края отверстия
10 мм от оси центрального ребра до центра каждого отверстия
```

В модели это считается так:

```scad
lid_hole_y = wall + lid_hole_edge_from_long_side + lid_thread_d / 2;
lid_hole_positions = [
    [box_l / 2 - lid_hole_offset_from_rib, lid_hole_y],
    [box_l / 2 + lid_hole_offset_from_rib, lid_hole_y]
];
```

## Болты

Прорези под отвертку плохо показали себя в печати: при большом усилии паз
ломается. Поэтому в этой модели болты сделаны с шестигранной головкой под
гаечный ключ:

```scad
bolt_head_d = 16;
bolt_head_h = 5;
```

В сборочном виде болты показаны уже вкрученными в крышку:

```scad
bolt_insert_z = box_h - bolt_thread_length;
```

Резьбовая часть уходит в толщину крышки, а над верхней плоскостью торчит только
шестигранная головка.

## Экспорт

Из корня проекта:

```bash
./export_stl iphone_holder_box --source "models/iphone_holder/2026-07-03_iphone_15_pro_max_hollow_box.scad"
```

Для экспорта только крышки можно переопределить `parts` через `-D`, оставив
включенным только `top`.

Пример для проверки/экспорта только крышки:

```bash
openscad -o stl/iphone_holder_top.stl \
  -D 'parts=[["bottom",false],["top",true],["front",false],["back",false],["left",false],["right",false],["rib",false],["bolt_left_of_rib",false],["bolt_right_of_rib",false]]' \
  "models/iphone_holder/2026-07-03_iphone_15_pro_max_hollow_box.scad"
```

Пример для одного болта:

```bash
openscad -o stl/iphone_holder_bolt_left.stl \
  -D 'parts=[["bottom",false],["top",false],["front",false],["back",false],["left",false],["right",false],["rib",false],["bolt_left_of_rib",true],["bolt_right_of_rib",false]]' \
  "models/iphone_holder/2026-07-03_iphone_15_pro_max_hollow_box.scad"
```
