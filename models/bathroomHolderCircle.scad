include <bathroomHolderCircle/base_cylinder.scad>
include <bathroomHolderCircle/cutout_cylinder.scad>
include <bathroomHolderCircle/pin_cutouts.scad>
include <bathroomHolderCircle/tab_recess_cutout.scad>
include <bathroomHolderCircle/tab_perpendicular_peg_cutout.scad>

$fn = 64; // more then enought to print on BambuLab A1 mini

difference() {
    union() {
        difference() {
            base_cylinder();
            cutout_cylinder();
            tab_recess_cutout();
        }
        color([0.15, 0.23, 0.4])
            translate([0, -13, 3.8])
                cube([10, 10-0.01, 7.6], center = true);
    }
    pin_cutouts();
    tab_perpendicular_peg_cutout();
}