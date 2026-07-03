# OpenSCAD models

Проект содержит модели OpenSCAD, библиотеку резьбы и небольшой скрипт для
экспорта STL.

## Экспорт STL

Скрипт в корне проекта экспортирует модель в папку `stl/` с датой в имени:

```bash
./export_stl bathroomHolderCircle
```

Он возьмет `models/bathroomHolderCircle.scad` и создаст файл вида:

```text
stl/YYYY-MM-DD_bathroomHolderCircle.stl
```

Для сборочной модели, где детали включаются флагами:

```bash
./export_stl bolt --source models/2026-07-02_sample_screw_and_hole.scad -- -D show_plate=false
./export_stl plate --source models/2026-07-02_sample_screw_and_hole.scad -- -D show_bolt=false
```

Все аргументы после `--` передаются напрямую в `openscad`.

## Как задавать пару резьб

В модели `models/2026-07-02_sample_screw_and_hole.scad` пара резьб задается так:

```scad
bolt_d     = 10;   // номинальный наружный диаметр, например M10
bolt_pitch = 1.5;  // шаг резьбы
bolt_h     = 10;   // длина резьбы

thread_fit_clearance = 0.4; // добавка к диаметру внутренней резьбы
bolt_fit_clearance   = 0.2; // вычитание из диаметра внешней резьбы
thread_leadin        = 2;   // фаска на обоих концах резьбы
```

Главное правило:

```scad
// Наружная резьба, болт
metric_thread(
    diameter = bolt_d - bolt_fit_clearance,
    pitch = bolt_pitch,
    length = bolt_h,
    internal = false
);

// Внутренняя резьба, отверстие
metric_thread(
    diameter = bolt_d + thread_fit_clearance,
    pitch = bolt_pitch,
    length = bolt_h,
    internal = true
);
```

То есть у болта и отверстия должен быть один и тот же `pitch`. Внутренняя
резьба для печати делается немного больше, а внешняя резьба болта немного
меньше.

## Что означает `thread_fit_clearance`

`thread_fit_clearance` - это добавка к диаметру внутренней резьбы, не к радиусу.
`bolt_fit_clearance` - это уменьшение диаметра внешней резьбы, тоже не радиуса.

Например:

```scad
bolt_d = 10;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
```

Внутренний резьбовой вырез строится как `10.4 мм`, а болт печатается как
`9.8 мм`. Разница между внутренней и внешней резьбой получается `0.6 мм` по
диаметру, то есть примерно `0.3 мм` на сторону.

Для Bambu Lab A1 mini, PETG и сопла 0.4 мм разумная стартовая зона:

```scad
thread_fit_clearance = 0.3; // плотнее
thread_fit_clearance = 0.4; // текущий внутренний зазор
thread_fit_clearance = 0.5; // свободнее

bolt_fit_clearance = 0.0; // внешний болт номинального диаметра
bolt_fit_clearance = 0.2; // текущий тестовый болт, легче вкручивается
bolt_fit_clearance = 0.3; // еще свободнее
```

Если резьба не начинает вкручиваться или идет только с большим усилием,
сначала увеличивай `bolt_fit_clearance` на `0.1`, если перепечатываешь только
болт. Если печатаешь обе детали заново, можно подбирать и `thread_fit_clearance`.
Если болтается, уменьшай соответствующий зазор на `0.1`.

## Заход резьбы

Для печатных деталей полезно включать заходную фаску:

```scad
thread_leadin = 2;
```

И передавать ее в обе резьбы:

```scad
leadin = thread_leadin
```

В библиотеке `threads.scad` значение `2` означает фаску с двух сторон. Это
помогает резьбе начать входить без закусывания на самом краю.

## Что менять для другого размера

Для M8x1.25:

```scad
bolt_d = 8;
bolt_pitch = 1.25;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
```

Для M12x1.75:

```scad
bolt_d = 12;
bolt_pitch = 1.75;
thread_fit_clearance = 0.4;
bolt_fit_clearance = 0.2;
```

Когда блок уже напечатан, удобнее подбирать только `bolt_fit_clearance` и
перепечатывать болт. Шаг `bolt_pitch` должен совпадать у внешней и внутренней
резьбы.

## Preview и финальный рендер

В модели используется:

```scad
preview_fast = $preview;
```

В preview OpenSCAD (`F5`) резьба заменяется цилиндрами, чтобы модель быстро
крутилась. При финальном render/export (`F6` или `./export_stl`) строится
настоящая резьба.
