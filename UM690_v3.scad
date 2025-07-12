include <BOSL2/std.scad>
use <pwm12v.scad>
$fn = 40;

// === Global Parameters ===
corner_radius = 11; // Body chamfer radius

// === Body ===
box_width = 126.3;    // Body width
box_height = 127.8;   // Body length
wall_thickness = 1.5; // Wall thickness
base_thickness = 2;   // Base thickness
main_height = 10;     // Height to the lip

// === Lip ===
lip_width = 124.5;    // Lip width
lip_height = 126;     // Lip height
lip_offset_height = 1.8; // Lip height above the body
lip_thickness = 1.5;  // Lip thickness

// === Mounts ===
screw_height_offset = 9.5; // Distance from bottom to top of mount
screw_total_height = main_height + screw_height_offset; // Total mount height
screw_diameter = 2.8;    // Screw diameter
screw_head_diameter = 4.5; // Screw head diameter
screw_cap_thickness = 2;  // Mount cap thickness
mount_diameter = 8;       // Mount outer diameter
mount_spacing_x = 112;    // Mount spacing along X
mount_spacing_y = 111;    // Mount spacing along Y

// === Mount Positions ===
pos_crews = [
    [ mount_spacing_x/2,  mount_spacing_y/2],
    [-mount_spacing_x/2,  mount_spacing_y/2],
    [-mount_spacing_x/2, -mount_spacing_y/2],
    [ mount_spacing_x/2, -mount_spacing_y/2]
];

lamella_thickness = 4;

// === Grille ===
grille_width = lip_width - 2 * 15; // Leave 10 mm margin on each side
grille_height = 5; // Grille height
grille_center_x = 0; // Center along X
grille_center_y = 0; // Center along Y
grille_z_offset = main_height - grille_height / 2 - 2;
grille_depth = 10; // Depth
grille_lamella_count = 14; // Number of openings
grille_lamella_thickness = 2;

// === Wire Mounts ===
wire_xy = [
    [lip_width/2 - 15  , lip_height/2 - 20, 90],
    [-lip_width/2 + 15 , lip_height/2 - 20, 90],
    [lip_width/2 - 15  , -lip_height/2 + 15, 90],
    [-lip_width/2 + 15 , -lip_height/2 + 15, 90],

    //[-lip_width/2 + 15 , 0, 90],
    //[0              , lip_height/2 - 20, 0],
    //[0              , -lip_height/2 + 18, 0],
];

// SETTINGS
with_pwm = true;
with_wires = true;

if (with_pwm){
    // PWM plate
    translate([lip_width/2-base_thickness, -28, base_thickness])
        rotate([0,0,90])
            pwm_plate();

    // UM690 case with PWM
    pwm_place(mv=[lip_width/2-base_thickness, -28, base_thickness], rot=[0,0,90], bottom_thin=base_thickness, bt_top=0.1)
        main();
}else{
    // UM690 case without PWM
    main();
}

// 8010 cooler
translate([0, 0, 5+2])
    color([0.5, 0.5, 0, 0.2])
        %cube([80,80,10], center=true);

// Body
module main(){
    difference() {
        union() {
            create_main_case(main_height, wall_thickness, base_thickness); // Body
            create_raised_lip(lip_offset_height, lip_thickness);         // Lip
            for (pos = pos_crews) {
                create_mount_boss(pos[0], pos[1]);
            }
            // Wires
            if (with_wires){
                for (wxy = wire_xy) {
                    translate([wxy[0], wxy[1], base_thickness])
                        rotate([0,0,wxy[2]])
                            wire_lock();
                }
            }
        }

        for (pos = pos_crews) {
            create_screw_counterbore(pos[0], pos[1]);
        }

        create_grill_8010_mount(0, 0, 5);

        translate([0, box_height/2+1, grille_z_offset])
            rotate([90,0,0])
                linear_extrude(grille_depth)
                    create_ventilation_grille(grille_width, grille_height, num_lamellae=grille_lamella_count, lamella_width=grille_lamella_thickness);

        translate([0, -(box_height/2+1), grille_z_offset])
            rotate([-90,0,0])
                    linear_extrude(grille_depth)
                        create_ventilation_grille(grille_width, grille_height, num_lamellae=grille_lamella_count, lamella_width=grille_lamella_thickness);
    }
}

translate([0, 100, 0]) %wire_lock();

// Wire lock
module wire_lock(w=8, h=6, d=2){
    r = (w-0.8*2) / 2;
    difference(){
        cube([w, d, h]);
        translate([w/2, 0, h/2])
            rotate([0, 45, 0])
                cube([r, 6, r], center=true);
    }
}

module create_main_case(h, thin, base_thin){
    box = square([box_width, box_height], center=true);
    rbox = round_corners(box, radius=corner_radius);
    difference(){
        offset_sweep(rbox, height=h, check_valid=false);
        up(base_thin)
            offset_sweep(offset(rbox, r=-thin, closed=true), height=h);
    }
}

// === Internal Lip ===
module create_raised_lip(dh, thin){
    box = square([lip_width, lip_height], center=true);
    rbox = round_corners(box, radius=corner_radius);
    H = dh + main_height;
    echo("H:", H, "h:", main_height, "dh:", dh);
    difference(){
        offset_sweep(rbox, height=H, check_valid=false);
        offset_sweep(offset(rbox, r=-thin, closed=true), height=H+1);
    }
}

// === Mount Boss ===
module create_mount_boss(x, y){
    translate([x, y, 0.01]) color("blue")
    difference() {
        cylinder(h = screw_total_height, r=mount_diameter/2); // Outer cylinder
        cylinder(screw_total_height + 0.1, r=screw_diameter/2); // Cutout for screw
    }
}

// === Counterbore for Screw Head ===
module create_screw_counterbore(x, y){
    h1 = screw_total_height - screw_cap_thickness;
    w_chamf = (screw_head_diameter - screw_diameter)/2;

    hole = circle(d = screw_head_diameter);
    translate([x, y, 0]) color("green")
        offset_sweep(hole, height=h1, top=os_chamfer(width=w_chamf));
}

module create_grill_screw(d, h, coord=[0,0,0]){
    translate(coord)
        cyl(h, r=d/2, chamfer=-1, center=false);
}

// === Mounting Platform with Grille for 80x10 mm Cooler ===
module create_grill_8010_mount(x, y, th_grill, num_lamellae = 10, w_lamella=1.2) {
    dist_mount = 71.5; // Distance between mounting holes
    d_mount = 5;     // Mounting hole diameter
    r_mount = d_mount / 2;
    d_grill = 75;      // Grille diameter
    //w_lamella = 1.2;   // Lamella width
    spacing = d_grill / (num_lamellae - 1);
    dm = dist_mount/2;

    translate([x, y, -0.01]) {
        union(){
            //grill_screw(d_mount, th_grill, [dist_mount/2-8, dist_mount/2-8, 0]);
            create_grill_screw(d_mount, th_grill, [dm, dm, 0]);
            create_grill_screw(d_mount, th_grill, [-dm, dm, 0]);
            create_grill_screw(d_mount, th_grill, [-dm, -dm, 0]);
            create_grill_screw(d_mount, th_grill, [dm, -dm, 0]);

            linear_extrude(th_grill) {
                union() {
                    // Mounting holes
                    /*
                    translate([dist_mount/2, dist_mount/2, 0]) circle(r = r_mount);
                    translate([-dist_mount/2, dist_mount/2, 0]) circle(r = r_mount);
                    translate([-dist_mount/2, -dist_mount/2, 0]) circle(r = r_mount);
                    translate([dist_mount/2, -dist_mount/2, 0]) circle(r = r_mount);
                    */

                    // Grille
                    difference() {
                        circle(r = d_grill / 2); // Outer circle

                        for(i = [0 : num_lamellae - 1]) {
                            pos = -d_grill/2 + i * spacing;

                            // Vertical lamella
                            translate([pos, 0])
                                square([w_lamella, d_grill], center = true);

                            // Horizontal lamella
                            translate([0, pos])
                                square([d_grill, w_lamella], center = true);
                        }
                    }
                }
            }
        }
    }
}

module create_ventilation_grille(width, height, num_lamellae=10, lamella_width=1.5) {
    // Calculate spacing between lamellae
    spacing = width / (num_lamellae - 1);
    echo("space:", spacing);
    difference() {
        // Main rectangular shape of the grille
        square([width-0.1, height-0.1], center=true);
        // Vertical lamellae
        for(i = [0 : num_lamellae - 1]) {
            pos = -width/2 + i * spacing;
            translate([pos, 0])
                square([lamella_width, height], center=true);
        }

        // Horizontal lamellae
        /*
        for(i = [0 : num_lamellae - 1]) {
            pos = -height/2 + i * spacing;
            translate([0, pos])
                square([width, lamella_width], center=true);
        }*/
    }
}
