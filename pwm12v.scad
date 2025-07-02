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

// корпус PWM
module pwm_plate(z){
    translate([0, 0, z]) %cube([w_pwm, h_pwm, z_pwm]); 
}

// оболочка корпуса
module casebox(w, h, z, thin){
    box = square([w, h]);
    //rbox = round_corners(box, radius=rad_fillet);
    translate([-1, 0, 0]) difference(){
        offset_sweep(box, height=z, check_valid=false);
        up(thin)
            offset_sweep(offset(box, r=-thin, closed=true), height=z);
        // право
        translate([w-thin, 6, thin])
            cube([thin, 13, z_pwm]);
        // лево
        translate([0, thin, thin])
            cube([thin, h_pwm, z_pwm]);
    }
}

// корпус в сборе
module pwm_case(thin=1){
    pwm_place(mv=[0,0,thin],bottom_thin=thin){
        translate([-thin,-thin,0])
            casebox(w_pwm+2+thin*2, h_pwm+thin+thin*2+3, 12, thin);
    }
}

/*
разместить pwm на дочернем объекте

bottom_thin - толщина основания для формирования отверстий и кнопки
*/
module pwm_place(mv=[0,0,0], rot=[0,0,0], bottom_thin){
    difference(){
        union(){
            difference(){
                children();
                translate(mv) rotate(rot) pwm_clips_diff();
            }
            translate(mv) rotate(rot) pwm_clips();
            translate(mv) rotate(rot) pwm_holes_guard(z=bottom_thin);
        }
        translate(mv) rotate(rot) pwm_holes(d_led=pwm_led_d);
    }
    translate(mv) rotate(rot)pwm_button(z=bottom_thin);
}

// зацепы для крепления платы
module pwm_clips(thin=1.5, v_thin=1){
    //thin = 2.5; // выступ
    //v_thin = 1; // толщина
    h_len = 4; // горизонтальная длина

    fix_leg_d = 1; // выступ на ножке
    fix_leg_w = 15; // ширина ножки

    h_stop_1 = 4; // высота правой
    h_stop_2 = 2; // высота левой
    
    dy_left = 18;
    cyl_r = 2;
    cyl_d = cyl_r*2;
    cyl_r0 = screw_d/2;
    union(){
        // ограничитель верхнего угла
        translate([w_pwm, 0, z_pwm-h_stop_1]) cube([v_thin, thin, v_thin+h_stop_1]);
        // верхний правый борт
        translate([w_pwm-h_len, 0, z_pwm]) cube([h_len, thin, v_thin]);

        // левый угол верт
        translate([-v_thin, 0, z_pwm-h_stop_2]) cube([v_thin, thin, v_thin+h_stop_2]);
        // верхний левый борт
        translate([0, 0, z_pwm]) cube([h_len, thin, v_thin]);

        if (fix_type == 1){
        // левый крючок
            translate([thin+dy_left, h_pwm-fix_leg_d, z_pwm]) cube([fix_leg_w, thin + fix_leg_d, v_thin]);
            translate([thin+dy_left, h_pwm, 0]) cube([fix_leg_w, thin, z_pwm]); // ножка
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

// вырез для гибкой ножки и шурупа
module pwm_clips_diff(){
    fix_pwm_w = 1.5; // размер выступа
    fix_leg_w = 15; // длинна выступа

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
module pwm_holes(bottom_z=10, led_z = 4, d_led = 1.9){
    //led_z = 4; // дистанция до светодиодов
    //d_led = 1.9; // диметр отверсия для световода
    r_led = d_led / 2;
    d_led_leg = 2.2; // диаметр ножки световода
    r_led_leg = d_led_leg / 2;
    delta_led = 3; // расстояние между светодиодами
    pwm_bt_dhole = pwm_bt_d_hole + 0.4; // диаметр дырки под кнопку
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
    pwm_bt_d2 = pwm_bt_d_hole + 1; // диаметр кнопки за отверстием, шире что бы не выпадала
    pwm_bt_h = pwm_bt_h1 + pwm_bt_h2;
    translate([pwm_hole_delta, 0, -z])
        translate([pwm_bt_delta_x, pwm_bt_delta_y, 0]) 
        union(){
            cylinder(pwm_bt_h1 + pwm_bt_dh, r=pwm_bt_d_hole/2, $fn=40); // низ
            translate([0,0,pwm_bt_h1 + pwm_bt_dh]) 
                cylinder(pwm_bt_h2 - pwm_bt_dh, r=pwm_bt_d2/2, $fn=40); // внутри корпуса , chamfer1=2
        }
}