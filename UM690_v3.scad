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

// Модуль PWM
w_pwm = 50; // длинна
h_pwm = 18; // ширина
z_pwm = 7.5; // высота

pwm_bt_dh = 0.2; // отступ от нижнего слоя
pwm_bt_h2 = 4.2; // высота от кнопки до корпуса внутри
pwm_bt_h1 = th_base; // толщина внутри отверстия
pwm_bt_h = pwm_bt_h1 + pwm_bt_h2;
pwm_bt_d_hole = 5.4; // диаметр внутри отверсия
pwm_bt_d2 = pwm_bt_d_hole + 1; // диаметр кнопки за отверстием, шире что бы не выпадала
pwm_bt_dhole = pwm_bt_d_hole + 0.4; // диаметр дырки под кнопку

pwm_led_d = 2.0; // диаметор световодов

/// === Основной корпус UM690 ===
// модуль pwm
pwm_x = w_bort / 2 - th_bort;
pwm_y = -w_pwm / 2;


pwm_hole_delta = 24+0.2; // смещение дырок
pwm_bt_delta_x = 13.5; // смещение кнопки
pwm_bt_delta_y = 9.6;

debug_pwm = false;

//translate([pwm_x, pwm_y, th_base]) color("red", alpha=0.3) rotate([0,0,90]) %cube([w_pwm, h_pwm, z_pwm]);
// 8010 cooller
translate([0, 0, 5+2]) color([0.5, 0.5, 0, 0.2])  %cube([80,80,10], center=true);

translate([120, 0, 0]) %pwm_holes();

translate([90, 20, 0]) %pwm_button();

translate([100, 0, 0]) %pwm_clips();


// отдельно стоящая кнопка PWM
translate([pwm_x - h_pwm + pwm_bt_delta_y + 3, pwm_y + pwm_hole_delta + pwm_bt_delta_x, 0]) 
    color("green") pwm_button();

module cut_pwm(d_cut = 4){
    translate([pwm_x-h_pwm-d_cut, pwm_y-d_cut, 0]) 
        color([0.7, 0.2, 0.5, 0.4])  
            cube([h_pwm+d_cut*2,w_pwm+d_cut*2,z_pwm+d_cut*2]);
}

if (debug_pwm){
    intersection() {
        main();
        cut_pwm();
    }
}else{
    main();
}


// корпус
module main(){
    difference() {
        union() {
            main_case(ht_main, th_wall, th_base); // корпус
            raised_lip(dh_bort, th_bort);         // бортик
            for (pos = pos_crews) {
                mount_boss(pos[0], pos[1]);
            }
            
            // крепление pwm
            translate([w_bort/2 - th_bort, w_pwm/2, th_base]) 
                color([0, 0.5, 0.5]) 
                    pwm_clips();
            
            // кожух на светодиоды
            translate([pwm_x - h_pwm, pwm_y, th_base]) 
                rotate([0, 0, 90]) 
                    pwm_holes_guard();
        }
        
        // индикаторы и кнопка
        translate([pwm_x - h_pwm, pwm_y, th_base]) 
            rotate([0, 0, 90]) 
                pwm_holes(d_led=pwm_led_d);

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

module pwm_clips(){
    fix_pwm_w = 2; // размер выступа
    fix_pwm_h = 15; // длинна выступа
    fix_pwm_z = 2; // толщина выступа
    fix_left_d = 1; // выступ на ножке

    h_stop_1 = 5;
    h_stop_2 = 2;
    fix_pwm_w2 = 1;
    fix_pwm_h2 = 2;
    fix_pwm_z2 = 1;
    dy_left = 13;
    union(){
        // ограничитель верхнего угла
        translate([-fix_pwm_w, 0, z_pwm-h_stop_1]) cube([fix_pwm_w, fix_pwm_w, fix_pwm_z+h_stop_1]);
        // верхний правый борт
        translate([-fix_pwm_w,-fix_pwm_h,z_pwm]) cube([fix_pwm_w, fix_pwm_h, fix_pwm_z]);

        // левый угл
        translate([-fix_pwm_w2, -w_pwm - fix_pwm_w2, z_pwm-h_stop_2]) cube([fix_pwm_w2, fix_pwm_w2, fix_pwm_z2+h_stop_2]);
        // верхний левый борт
        translate([-fix_pwm_w2,-w_pwm,z_pwm]) cube([fix_pwm_w2, fix_pwm_h2, fix_pwm_z2]);

        //translate([0,])
        // левая стенка
        translate([-h_pwm-fix_pwm_w, -fix_pwm_h-dy_left, z_pwm]) cube([fix_pwm_w + fix_left_d, fix_pwm_h, fix_pwm_z]);
        translate([-h_pwm-fix_pwm_w, -fix_pwm_h-dy_left, 0]) cube([fix_pwm_w, fix_pwm_h, z_pwm]); // ножка
    }
}

// отверстия для светодиодов и кнопки pwm модуля
module pwm_holes(bottom_z=10,led_z = 4, d_led = 1.9){
    //led_z = 4; // дистанция до светодиодов
    //d_led = 1.9; // диметр отверсия для световода
    r_led = d_led / 2;
    d_led_leg = 2.2; // диаметр ножки световода
    r_led_leg = d_led_leg / 2;
    delta_led = 3; // расстояние между светодиодами
    button_r = pwm_bt_dhole/2; // радиус выреза под кнопку
    translate([0, -h_pwm, 0]) %cube([w_pwm, h_pwm, z_pwm]); // корпус PWM
    translate([pwm_hole_delta, -3, 0])
        color("yellow") 
        translate([0,0,-bottom_z])
        linear_extrude(led_z + bottom_z){
            union(){
                circle(r=r_led);
                translate([delta_led, 0]) circle(r=r_led);
                translate([delta_led * 2, 0]) circle(r=r_led);
                translate([pwm_bt_delta_x, -pwm_bt_delta_y]) circle(r=button_r);
            }
        }
}

module pwm_holes_guard(led_z = 4, d_led_leg = 3){
    //d_led_leg = 2.2; // диаметр ножки световода
    r_led_leg = d_led_leg / 2;
    delta_led = 3; // расстояние между светодиодами
    d1 = 4;
    h = delta_led*2+d1;
    w = 3 + 3;
    
    translate([pwm_hole_delta-d1/2, -w, 0])
        cube([h, w , led_z]);
        /*
        union(){
            cylinder(led_z, r=r_led_leg);
            translate([delta_led, 0]) cylinder(led_z, r=r_led_leg);
            translate([delta_led * 2, 0]) cylinder(led_z, r=r_led_leg);
        }*/
}

// кнопка PWM
module pwm_button(){
    union(){
        cylinder(pwm_bt_h1 + pwm_bt_dh, r=pwm_bt_d_hole/2); // низ
        translate([0,0,pwm_bt_h1 + pwm_bt_dh]) cylinder(pwm_bt_h2 - pwm_bt_dh, r=pwm_bt_d2/2); // внутри корпуса , chamfer1=2
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
