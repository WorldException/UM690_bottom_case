include <BOSL2/std.scad>

$fn = 60;

// === Глобальные параметры ===
rad_fillet = 11; // Радиус фаски корпуса

// === Корпус ===
w_box = 126.3;    // Ширина корпуса
h_box = 127.8;    // Длинна корпуса
th_wall = 1.5;    // Толщина стенок
th_base = 2;      // Толщина основания
ht_main = 10;     // Высота до бортика

// === Бортик ===
w_bort = 124.5;     // Ширина бортика
h_bort = 126;   // Высота бортика
dh_bort = 1.8;    // Высота бортика над корпусом
th_bort = 1.5;    // Толщина бортика

// === Крепления ===
dh_crew = 9.5;     // Расстояние от низа до верха крепления
ht_crew = ht_main + dh_crew; // Полная высота крепления
d_screw = 2.8;    // Диаметр болта
d_head = 4.5;      // Диаметр головки болта
ht_cap = 2;        // Толщина крышки крепления
d_ext = 8;         // Внешний диаметр крепления
dist_x = 112;      // Расстояние между креплениями по X
dist_y = 111;      // Расстояние между креплениями по Y

// === Позиции креплений ===
pos_crews = [
    [ dist_x/2,  dist_y/2],
    [-dist_x/2,  dist_y/2],
    [-dist_x/2, -dist_y/2],
    [ dist_x/2, -dist_y/2]
];

lamella_width=4;

// Решетка
grille_width = w_bort - 2 * 15; // Оставляем поле 10 мм по краям
grille_height = 5; // высота решеток
grille_pos_x = 0; // Центрирование по X
grille_pos_y = 0; // Центрирование по Y
grille_pos_z = ht_main - grille_height/ 2 - 2;
grille_extrude=10; // глубина
grille_count = 14; // кол-во отверстий
grille_lamella_width = 2;


// 8010 cooller
translate([0, 0, 5+2]) color([0.5, 0.5, 0, 0.2])  %cube([80,80,10], center=true);

use <pwm12v.scad>


// pwm plate
translate([w_bort/2 - th_bort, -28, th_base]) 
    rotate([0,0,90]) 
        pwm_plate();

with_pwm=true;

if (with_pwm){
    // UM690 case with pwm
    pwm_place(mv=[w_bort/2-th_bort, -28, th_base], rot=[0,0,90], bottom_thin=th_base, bt_top=0.1)
        main();
}else{
    // UM690 case without pwm
    main();
}


/// ---- modules -----

// корпус
module main(){
    difference() {
        union() {
            main_case(ht_main, th_wall, th_base); // корпус
            raised_lip(dh_bort, th_bort);         // бортик
            for (pos = pos_crews) {
                mount_boss(pos[0], pos[1]);
            }
        }

        for (pos = pos_crews) {
            screw_counterbore(pos[0], pos[1]);
        }
        
        grill_8010_mount(0, 0, 5);
        
        translate([0, h_box/2+1, grille_pos_z]) 
            rotate([90,0,0]) 
                linear_extrude(grille_extrude)
                    ventilation_grille(grille_width, grille_height, num_lamellae=grille_count, lamella_width=grille_lamella_width);
        
        translate([0, -(h_box/2+1), grille_pos_z]) 
            rotate([-90,0,0])
                    linear_extrude(grille_extrude)
                        ventilation_grille(grille_width, grille_height, num_lamellae=grille_count, lamella_width=grille_lamella_width);
    }
}

module main_case(h, thin, base_thin){
    box = square([w_box, h_box], center=true);
    rbox = round_corners(box, radius=rad_fillet);
    difference(){
        offset_sweep(rbox, height=h, check_valid=false);
        up(base_thin)
            offset_sweep(offset(rbox, r=-thin, closed=true), height=h);
    }
}

// === Внутренний бортик ===
module raised_lip(dh, thin){
    box = square([w_bort, h_bort], center=true);
    rbox = round_corners(box, radius=rad_fillet);
    H = dh + ht_main;
    echo("H:", H, "h:", ht_main, "dh:", dh);
    difference(){
        offset_sweep(rbox, height=H, check_valid=false);
        offset_sweep(offset(rbox, r=-thin, closed=true), height=H+1);
    }
}

// === Прилив под крепление ===
module mount_boss(x, y){
    translate([x, y, 0.01]) color("blue") 
    difference() {
        cylinder(h = ht_crew, r=d_ext/2); // внешний цилиндр
        cylinder(ht_crew + 0.1, r=d_screw/2); // вырез под болт
    }
}

// === Вырез под головку болта (counterbore) ===
module screw_counterbore(x, y){
    h1 = ht_crew - ht_cap;
    w_chamf = (d_head - d_screw)/2; 

    hole = circle(d = d_head);
    translate([x, y, 0]) color("green")
        offset_sweep(hole, height=h1, top=os_chamfer(width=w_chamf));
}

module grill_screw(d, h, coord=[0,0,0]){
    translate(coord)
        cyl(h, r=d/2, chamfer=-1, center=false);
}

// === Монтажная площадка с решёткой под кулер 80x10 мм ===
module grill_8010_mount(x, y, th_grill, num_lamellae = 10, w_lamella=1.2) {
    dist_mount = 71.5; // Расстояние между монтажными отверстиями
    d_mount = 5;     // Диаметр монтажных отверстий
    r_mount = d_mount / 2;
    d_grill = 75;      // Диаметр решётки
    //w_lamella = 1.2;   // Ширина ламели
    spacing = d_grill / (num_lamellae - 1);
    dm = dist_mount/2;
    
    translate([x, y, -0.01]) {
        union(){
            //grill_screw(d_mount, th_grill, [dist_mount/2-8, dist_mount/2-8, 0]);
            grill_screw(d_mount, th_grill, [dm, dm, 0]);
            grill_screw(d_mount, th_grill, [-dm, dm, 0]);
            grill_screw(d_mount, th_grill, [-dm, -dm, 0]);
            grill_screw(d_mount, th_grill, [dm, -dm, 0]);

            linear_extrude(th_grill) {
                union() {
                    // Монтажные отверстия
                    /*
                    translate([dist_mount/2, dist_mount/2, 0]) circle(r = r_mount);
                    translate([-dist_mount/2, dist_mount/2, 0]) circle(r = r_mount);
                    translate([-dist_mount/2, -dist_mount/2, 0]) circle(r = r_mount);
                    translate([dist_mount/2, -dist_mount/2, 0]) circle(r = r_mount);
                    */

                    // Решетка
                    difference() {
                        circle(r = d_grill / 2); // внешний круг

                        for(i = [0 : num_lamellae - 1]) {
                            pos = -d_grill/2 + i * spacing;

                            // Вертикальная ламель
                            translate([pos, 0])
                                square([w_lamella, d_grill], center = true);

                            // Горизонтальная ламель
                            translate([0, pos])
                                square([d_grill, w_lamella], center = true);
                        }
                    }
                }
            }
        }
    }
}

module ventilation_grille(width, height, num_lamellae = 10, lamella_width = 1.5) {
    // Расчёт шага между ламелями
    spacing = width / (num_lamellae - 1);
    echo("space:", spacing);
    difference() {
        // Основная прямоугольная форма решетки
        square([width-0.1, height-0.1], center=true);
        // Вертикальные ламели
        for(i = [0 : num_lamellae - 1]) {
            pos = -width/2 + i * spacing;
            translate([pos, 0])
                square([lamella_width, height], center=true);
        }

        // Горизонтальные ламели
        /*
        for(i = [0 : num_lamellae - 1]) {
            pos = -height/2 + i * spacing;
            translate([0, pos])
                square([width, lamella_width], center=true);
        }
        */
    }
}
