include <BOSL2/std.scad>

x = 0;
y = 0;
z = 2;

// Модуль PWM
w_pwm = 50; // длинна
h_pwm = 18; // ширина
z_pwm = 7.5; // высота

//pwm_bt_dh = 0.2; // отступ от нижнего слоя
//pwm_bt_h2 = 4.2; // высота от кнопки до корпуса внутри
//pwm_bt_h1 = z; // толщина внутри отверстия
//pwm_bt_h = pwm_bt_h1 + pwm_bt_h2;
pwm_bt_d_hole = 5.4; // диаметр внутри отверсия
pwm_bt_d2 = pwm_bt_d_hole + 1; // диаметр кнопки за отверстием, шире что бы не выпадала
pwm_bt_dhole = pwm_bt_d_hole + 0.4; // диаметр дырки под кнопку

pwm_led_d = 2.0; // диаметор световодов

/// === Основной корпус UM690 ===
// модуль pwm
pwm_x = x; //w_bort / 2 - th_bort;
pwm_y = w_pwm / 2;

pwm_hole_delta = 24+0.2; // смещение дырок
pwm_bt_delta_x = 13.5; // смещение кнопки
pwm_bt_delta_y = 4.4; //h_pwm-9.6+0.2; // от стенки до кнопки

debug=true;
box = true;

// тип зажима платы
/*
1 - защелка
2 - шуруп
*/
fix_type = 2;

// диаметр шурупа
screw_d = 2;

if (debug){
    pwm_plate(1);
    pwm_case(1);
}


module pwm_plate(z){
    translate([0, 0, z]) %cube([w_pwm, h_pwm, z_pwm]); // корпус PWM
}

module casebox(w, h, z, thin){
    box = square([w, h]);
    //rbox = round_corners(box, radius=rad_fillet);
    difference(){
        offset_sweep(box, height=z, check_valid=false);
        up(thin)
            offset_sweep(offset(box, r=-thin, closed=true), height=z);
        // право
        translate([w-thin, 6, thin])
            cube([thin, 13, z_pwm]);
        // лево
        translate([0, thin, thin])
            cube([thin, h-thin*2, z_pwm]);
    }
}

module pwm_case(z=0){
    thin = 1;
    translate([0,0,z]){
        difference() {
                union(){
                    difference(){
                        /*
                        translate([-thin,-thin,-z]) 
                            cube([w_pwm+thin*2, h_pwm+thin*2, z]);
                        
                        translate([-thin, -thin, 0])
                            cube([w_pwm+thin*2, thin, z_pwm+z]);
                        */
                        if (box){
                            translate([-thin,-thin,-z]) 
                                casebox(w_pwm+2+thin*2, h_pwm+thin+thin*2+3, 12, thin);
                        }
                        pwm_clips_diff();
                    }
                    pwm_union(z);
                }    
                pwm_diff();
        }
        pwm_button(z=z);
    }
}


module pwm_union(z){
    
    pwm_clips();
    pwm_holes_guard(z=z);
}
module pwm_diff(){
    pwm_holes();
}

// зацепы для крепления платы
module pwm_clips(){
    fix_pwm_w = 1.5; // размер выступа
    fix_pwm_h = 4; // длинна выступа
    fix_pwm_z = 1; // толщина выступа
    fix_leg_d = 1; // выступ на ножке
    fix_leg_w = 15; // длинна выступа

    h_stop_1 = 4;
    h_stop_2 = 2;
    fix_pwm_w2 = 1.5;
    fix_pwm_h2 = 2;
    fix_pwm_z2 = 1;
    dy_left = 18;
    cyl_r = 2;
    cyl_d = cyl_r*2;
    cyl_r0 = screw_d/2;
    union(){
        // ограничитель верхнего угла
        translate([w_pwm, 0, z_pwm-h_stop_1]) cube([fix_pwm_w, fix_pwm_w, fix_pwm_z+h_stop_1]);
        // верхний правый борт
        translate([w_pwm-fix_pwm_h, 0, z_pwm]) cube([fix_pwm_h, fix_pwm_w, fix_pwm_z]);

        // левый угл
        translate([-fix_pwm_w2, 0, z_pwm-h_stop_2]) cube([fix_pwm_w2, fix_pwm_w2, fix_pwm_z2+h_stop_2]);
        // верхний левый борт
        translate([-fix_pwm_w2+fix_pwm_w2, 0, z_pwm]) cube([fix_pwm_h2, fix_pwm_w2, fix_pwm_z2]);

        if (fix_type == 1){
        // левый крючок
            translate([fix_pwm_w+dy_left, h_pwm-fix_leg_d, z_pwm]) cube([fix_leg_w, fix_pwm_w + fix_leg_d, fix_pwm_z]);
            translate([fix_pwm_w+dy_left, h_pwm, 0]) cube([fix_leg_w, fix_pwm_w, z_pwm]); // ножка
        }
        if (fix_type == 2){
            // под шуруп
            translate([w_pwm/2, h_pwm-cyl_r+cyl_r0, 0]) 
                difference() {
                    //cylinder(z_pwm, r=cyl_r, $fn=40);
                    translate([-cyl_d, 0, 0]) cube([cyl_d*2, cyl_d, z_pwm-1.7]);
                    translate([0, cyl_r, z_pwm-5]) cylinder(z_pwm, r=cyl_r0, $fn=40);
                }
        }
        
    }
}

// вырез для гибкой ножки
module pwm_clips_diff(){
    fix_pwm_w = 1.5; // размер выступа
    fix_pwm_h = 4; // длинна выступа
    fix_pwm_z = 1; // толщина выступа
    fix_leg_d = 1; // выступ на ножке
    fix_leg_w = 15; // длинна выступа

    h_stop_1 = 4;
    h_stop_2 = 2;
    fix_pwm_w2 = 1.5;
    fix_pwm_h2 = 2;
    fix_pwm_z2 = 1;
    dy_left = 18;

    d = 0.5;

    if(fix_type==1){
        // ножка, вырез
        translate([fix_pwm_w+dy_left - d, h_pwm, 0]) cube([fix_leg_w+d*2, fix_pwm_w+d, z_pwm+fix_pwm_z2+d+0.2]);
    }
    if (fix_type==2){
        // вырез по шляпку
        translate([w_pwm/2, h_pwm, z_pwm]) cylinder(5, r=3.5 , $fn=40);
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

    translate([pwm_hole_delta, 0, 0])
        color("yellow")
        translate([0,0,-bottom_z])
        linear_extrude(led_z + bottom_z){
            union(){
                translate([0, h_pwm-3]) circle(r=r_led, $fn=40);
                translate([delta_led, h_pwm-3]) circle(r=r_led, $fn=40);
                translate([delta_led * 2, h_pwm-3]) circle(r=r_led, $fn=40);

                translate([pwm_bt_delta_x, pwm_bt_delta_y]) circle(r=button_r, $fn=40);
            }
        }
}

// блок для световодов
module pwm_holes_guard(z=0, led_z = 4, d_led_leg = 3){
    //d_led_leg = 2.2; // диаметр ножки световода
    r_led_leg = d_led_leg / 2;
    delta_led = 3; // расстояние между светодиодами
    d1 = 4;
    h = delta_led*2+d1;
    w = 3 + 3;
    
    translate([pwm_hole_delta-d1/2, h_pwm-w, 0])
        cube([h, w, led_z]);
        /*
        union(){
            cylinder(led_z, r=r_led_leg);
            translate([delta_led, 0]) cylinder(led_z, r=r_led_leg);
            translate([delta_led * 2, 0]) cylinder(led_z, r=r_led_leg);
        }*/
}

// кнопка PWM
module pwm_button(z=0){
    pwm_bt_dh = 0.2; // отступ от нижнего слоя
    pwm_bt_h2 = 4.2; // высота от кнопки до корпуса внутри
    pwm_bt_h1 = z; // толщина внутри отверстия
    pwm_bt_h = pwm_bt_h1 + pwm_bt_h2;
    translate([pwm_hole_delta, 0, -z])
        translate([pwm_bt_delta_x, pwm_bt_delta_y, 0]) 
        union(){
            cylinder(pwm_bt_h1 + pwm_bt_dh, r=pwm_bt_d_hole/2, $fn=40); // низ
            translate([0,0,pwm_bt_h1 + pwm_bt_dh]) 
                cylinder(pwm_bt_h2 - pwm_bt_dh, r=pwm_bt_d2/2, $fn=40); // внутри корпуса , chamfer1=2
        }
}