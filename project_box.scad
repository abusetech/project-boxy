EXTERIOR_WIDTH = 80;
EXTERIOR_HEIGHT = 80;
EXTERIOR_DEPTH = 30;    //Outside depth (of the box, not including the lid)
THICKNESS = 2; //Shell thickness
CHAMFER_RADIUS = 3; //Outside chamfer radius
LID = true; //Include lid?
BOX = true; //Indlude box?
EXTERIOR_CHAMFER_RES = 1;   //Resolution of the chamfer on the exterior of the box
BOX_CHAMFER_DIA = 6; //0 to disable
LID_LIP = true;
LID_LIP_THICKNESS = 2; 
LID_LIP_TOLERANCE = 0.5;
LID_LIP_WIDTH = 3;
BOARD_STANDOFFS = true; //Include board standoffs?
BOARD_STANDOFF_DEPTH = 5; //Height of the standoffs
BOARD_STANDOFF_WIDTH = 25; //Horizontal distance between the standoff centers
BOARD_STANDOFF_HEIGHT = 50; //Vertical distance between the standoff centers
BOARD_STANDOFF_DRILL = 2.5; //Size of the hole in the center of the standoffs
BOARD_STANDOFF_DIAMETER = 6; 
BOARD_STANDOFFS_OFFSET_WIDTH = 0; //Horizontal offset of the standoffs (relative to the center)
BOARD_STANDOFFS_OFFSET_HEIGHT = 0; //Vertical offset of the standoffs (relative to the center)
BOARD_STANDOFFS_CHAMFER = 4;    //Chamfer diameter of the board standoffs (0 to disable)
BOARD_STANDOFFS_RES = 2;
BOARD_STANDOFFS_DRILL_RES = 5;  //Number of faces in the board standoffs. 5 is recommended if you are using self tapping screws, otherwise choose something larger like 16 or 32.
LID_STANDOFF_DRILL = 3;             //Diameter of the hole placed in the standoffs that support the lid
LID_HOLE_DRILL = 3.5;   //Diameter of the holes in the lid
LID_DRILL_RES = 0.5;
LID_COUNTERSINK_DIA = 7;    //Lid screw countersink. Zero to disable.
LID_COUNTERSINK_DEPTH = 1.2;  //Lid screw countersink depth.
LID_STANDOFF_DIA = 10;              //Diameter of the standoffs that support the lid
LID_STANDOFF_HOLE_RES = 16;
LID_THICKNESS = 4;
PART_SPACING = 5;   //Distance between the lid and box if both are being rendered.
ROUND_HOLES = [[6,6.5,25,13],[6,6.5,25,0],[6,6.5,25,-13]]; //List of lists [[Face, Diameter, Position_h, Position_v], ...] face is a number from 1 to 6 representing the side the hole is on
ARDUINO_UNO = false; //Include an Arduino UNO footprint?
ARDUINO_UNO_ROTATION = 90;   //Supported rotations: 0,90,180,270
ARDUINO_UNO_OFFSET_X = 0;  
ARDUINO_UNO_OFFSET_Y = 0.5;

//Project box holes (ROUND_HOLES):
//Hole position is relative to the center of the EXTERIOR of the box.
//| Face #    | Position    |
//| 1         | Right       |
//| 2         | Left        |
//| 3         | Front       |
//| 4         | Back        |
//| 5         | Bottom      |
//| 6         | Lid         |

//Places copies of the child object at each corner of the specified rectangle
module rect_copy(x,y){
    translate([x/2,y/2,0])
    children();
    translate([-x/2,y/2,0])
    children();
    translate([x/2,-y/2,0])
    children();
    translate([-x/2,-y/2,0])
    children();
}

//Mirrors an object in all quadrants around the origin
module rec_mirror(){
    children();
    mirror([1,0,0])
    children();
    mirror([0,1,0]){
    children();
    mirror([1,0,0])
    children();
    }
}

//Base shape to extrude into chamfers
module chamfer_base(dia, res=$fs){
    difference(){
        square(dia/2);
        translate([dia/2,dia/2,0])
        circle(d=dia, $fs=res/4);
    }
}

//circular chamfer
module round_chamfer(minor, major, res=$fs){
    rotate_extrude($fs=res/2){
        translate([major/2,0,0])
        chamfer_base(minor, res=res);
    }
}

//linear chamfer with the right angle against the X axis with the chamfer facing + y
module linear_chamfer(distance, minor){
    translate([-distance/2,0,0])
    rotate([90,0,90])
    linear_extrude(distance){
        chamfer_base(minor);
    }
}

//Rounded rectangle shape used for creating the box
module rounded_rect(width, height, thickness, radius, res=2){
    x_disp = width - 2 * radius;
    y_disp = height - 2 * radius;

    hull(){
        rect_copy(x_disp,y_disp)
        cylinder(h=thickness, r=radius, $fs=res);
    }
}

//One single board standoff with chamfer, centered at the origin
module board_standoff(depth=BOARD_STANDOFF_DEPTH, d=BOARD_STANDOFF_DIAMETER, drill=BOARD_STANDOFF_DRILL, chamfer_dia=BOARD_STANDOFFS_CHAMFER,res=BOARD_STANDOFFS_RES, drill_res=BOARD_STANDOFFS_DRILL_RES){
    difference(){
        cylinder(h=depth, d=d, center=true, $fs=res/4);
        cylinder(h=depth, d=drill, center=true, $fn=drill_res);
    }
    if (BOARD_STANDOFFS_CHAMFER > 0){
        translate([0,0,-depth/2])
        round_chamfer(chamfer_dia,d,res=res);
    }
}

module board_standoffs(){
    translate([0,0,THICKNESS + BOARD_STANDOFF_DEPTH/2])
    rect_copy(BOARD_STANDOFF_WIDTH, BOARD_STANDOFF_HEIGHT)
    board_standoff();
}

//Standoffs for the lid in the corners of the box
//X,Y place the standoff relative to the drill, which is located at the origin
module lid_standoff(X=0, Y=0, offset=0, hole=true){
    intersection(){
        rec_mirror()
        translate([X,Y,EXTERIOR_DEPTH/2])
        difference(){
            hull(){
                translate([0,-(LID_STANDOFF_DIA+offset)/2,-EXTERIOR_DEPTH/2])
                cube([EXTERIOR_WIDTH+offset,EXTERIOR_HEIGHT+offset,EXTERIOR_DEPTH]);
                translate([-(LID_STANDOFF_DIA+offset)/2,0,-EXTERIOR_DEPTH/2])
                cube([EXTERIOR_WIDTH+offset,EXTERIOR_HEIGHT+offset,EXTERIOR_DEPTH]);
                cylinder(d=LID_STANDOFF_DIA+offset, h=EXTERIOR_DEPTH, center=true);
            }
            if(hole){
                cylinder(d=LID_STANDOFF_DRILL, h=EXTERIOR_DEPTH,center=true, $fn=LID_STANDOFF_HOLE_RES);
            }
        }
    rounded_rect(EXTERIOR_WIDTH,EXTERIOR_HEIGHT,EXTERIOR_DEPTH, CHAMFER_RADIUS,res=EXTERIOR_CHAMFER_RES);
    }
}

//chamfers placed around the standoffs for the lid.
module lid_standoff_chamfers(dia, X=0, Y=0){
    intersection(){
        rec_mirror(){
            translate([X,Y,THICKNESS])
            round_chamfer(dia, LID_STANDOFF_DIA);
            translate([X+EXTERIOR_WIDTH/4,Y-LID_STANDOFF_DIA/2,THICKNESS])
            rotate([0,0,180])
            linear_chamfer(EXTERIOR_WIDTH/2, dia);
            translate([X-LID_STANDOFF_DIA/2,Y+EXTERIOR_HEIGHT/4,THICKNESS])
            rotate([0,0,90])
            linear_chamfer(EXTERIOR_HEIGHT/2, dia);
        }
        rounded_rect(EXTERIOR_WIDTH,EXTERIOR_HEIGHT,EXTERIOR_DEPTH, CHAMFER_RADIUS,res=EXTERIOR_CHAMFER_RES);
    }
}



module box_chamfers(dia){
    intersection(){
        union(){
            translate([0,-EXTERIOR_HEIGHT/2+THICKNESS,THICKNESS])
            linear_chamfer(EXTERIOR_WIDTH, dia);
            translate([0,EXTERIOR_HEIGHT/2-THICKNESS,THICKNESS])
            rotate([0,0,180])
            linear_chamfer(EXTERIOR_WIDTH, dia);
            translate([EXTERIOR_WIDTH/2-THICKNESS,0,THICKNESS])
            rotate([0,0,90])
            linear_chamfer(EXTERIOR_HEIGHT, dia);
            translate([-EXTERIOR_WIDTH/2+THICKNESS,0,THICKNESS])
            rotate([0,0,-90])
            linear_chamfer(EXTERIOR_HEIGHT, dia);
        }
                    rounded_rect(EXTERIOR_WIDTH-THICKNESS*2,EXTERIOR_HEIGHT-THICKNESS*2,EXTERIOR_DEPTH, CHAMFER_RADIUS, res=EXTERIOR_CHAMFER_RES);
    }
}



//rounded rectangular base for the lid
module lid_base(X=0,Y=0){
    difference(){
        rounded_rect(EXTERIOR_WIDTH,EXTERIOR_HEIGHT,LID_THICKNESS, CHAMFER_RADIUS, res=EXTERIOR_CHAMFER_RES);
        rec_mirror(){
        translate([X,Y,LID_THICKNESS/2])
            cylinder(d=LID_HOLE_DRILL, h=LID_THICKNESS, center=true, $fs=LID_DRILL_RES);
        translate([X,Y,0])
            cylinder(d=LID_COUNTERSINK_DIA, h=LID_COUNTERSINK_DEPTH, center=false, $fs=LID_DRILL_RES);
        }
    }
}

//List of lists [[Face, Diameter, Position_h, Position_v], ...] face is a number from 1 to 6 representing the side the hole is on
module mounting_hole_transform(face, h, v){
     if (face == 1){
         //right face
         translate([EXTERIOR_WIDTH/2-THICKNESS/2,h,v + EXTERIOR_DEPTH/2])
         rotate([0,90,0])
         children();
     }else if(face == 2){
         //left face
         translate([-EXTERIOR_WIDTH/2+THICKNESS/2,h,v + EXTERIOR_DEPTH/2])
         rotate([0,90,0])
         children();
     }else if(face == 3){
         //front (+y) face
         translate([h, +EXTERIOR_HEIGHT/2 - THICKNESS/2, v + EXTERIOR_DEPTH/2])
         rotate([90, 0,0])
         children();
     }else if(face == 4){
         //back (-y) face 
         translate([h, -EXTERIOR_HEIGHT/2 + THICKNESS/2, v + EXTERIOR_DEPTH/2])
         rotate([90, 0,0])
         children();
     }else if(face == 5){
         //bottom face
         translate([v, h, THICKNESS/2])
         children();
     }else if(face == 6){
         //lid
         translate([v, h, LID_THICKNESS/2])
         children();
     }
}

//List of lists [[Face, Diameter, Position_h, Position_v], ...] face is a number from 1 to 6 representing the side the hole is on
module box_mounting_holes(){
 for(hole = ROUND_HOLES){
     if(hole[0] != 6){
         mounting_hole_transform(hole[0], hole[2], hole[3])
         cylinder(h=THICKNESS * 1.05, d=hole[1], center=true);
     }
 }
}

module lid_mounting_holes(){
 for(hole = ROUND_HOLES){
     if(hole[0] == 6){
         mounting_hole_transform(hole[0], hole[2], hole[3])
         cylinder(h=LID_THICKNESS, d=hole[1], center=true);
     }
 }
}

//lip that goes around the lid to align it to the box
module lid_lip(X=0,Y=0,tolerance=0.5){
    difference(){
    rounded_rect(EXTERIOR_WIDTH-tolerance*2,EXTERIOR_HEIGHT-tolerance*2,LID_LIP_THICKNESS, CHAMFER_RADIUS);
    lid_standoff(X,Y,tolerance,false);
    }
}

//Arduino UNO R3 footprint with the origin at the center of the board nearest the barrel jack.
//Board is 53.34mm wide along the short edge
module arduino_uno_R3_layout_standoffs(){
    //board_standoff(depth=BOARD_STANDOFF_DEPTH, d=BOARD_STANDOFF_DIAMETER, drill=BOARD_STANDOFF_DRILL, chamfer_dia=BOARD_STANDOFFS_CHAMFER,res=BOARD_STANDOFFS_RES, drill_res=BOARD_STANDOFFS_DRILL_RES)
    translate([0,-53.34/2,BOARD_STANDOFF_DEPTH/2+THICKNESS]){
        translate([15.24,50.80,0])
            board_standoff(drill=BOARD_STANDOFF_DRILL);
        translate([66.04,35.56,0])
            board_standoff(drill=BOARD_STANDOFF_DRILL);
        translate([66.04,7.62,0])
            board_standoff(drill=BOARD_STANDOFF_DRILL);
        translate([13.97,2.54,0])
            board_standoff(drill=BOARD_STANDOFF_DRILL);
    }
}

module arduino_uno_R3_layout_cuts(){
    hole_tolerance = 1;
    jack_length = 15;
    translate([0,-53.34/2,0]){
    //USB jack.
    translate([-jack_length/2,38.09,10.8/2 + THICKNESS + BOARD_STANDOFF_DEPTH + 1.6])
        cube([jack_length,12.88+hole_tolerance,10.8+hole_tolerance],center=true);
    //Barrel jack.
    translate([-jack_length/2,7.62,(10.8+hole_tolerance)/2 + THICKNESS + BOARD_STANDOFF_DEPTH + 1.6])
        cube([jack_length,9+hole_tolerance,10.9+hole_tolerance],center=true);
    }
}
//ARDUINO_UNO = false;
//ARDUINO_UNO_ROTATION = 0;
//ARDUINO_UNO_OFFSET_X = 0;
//ARDUINO_UNO_OFFSET_Y = 0;

module uno_rotation(rot){
    if(rot == 0){
        translate([ARDUINO_UNO_OFFSET_X - EXTERIOR_WIDTH/2 + THICKNESS*1.5, ARDUINO_UNO_OFFSET_Y,0])
        rotate([0,0,rot])
        children();
    }if(rot == 90){
        translate([ARDUINO_UNO_OFFSET_X, ARDUINO_UNO_OFFSET_Y  - EXTERIOR_HEIGHT/2 + THICKNESS*1.5,0])
        rotate([0,0,rot])
        children();
    }if(rot == 180){
        translate([ARDUINO_UNO_OFFSET_X + EXTERIOR_WIDTH/2 - THICKNESS*1.5, ARDUINO_UNO_OFFSET_Y,0])
        rotate([0,0,rot])
        children();
    }if(rot == 270){
        translate([ARDUINO_UNO_OFFSET_X, ARDUINO_UNO_OFFSET_Y  + EXTERIOR_HEIGHT/2 - THICKNESS*1.5,0])
        rotate([0,0,rot])
        children();
    }
}

module arduino_uno_R3(cuts=false){
    if(ARDUINO_UNO){
        uno_rotation(ARDUINO_UNO_ROTATION)
        if(cuts){
            arduino_uno_R3_layout_cuts();
        }else{
            arduino_uno_R3_layout_standoffs();
        }
    }
}

module project_name(){
    size =  4;
    height = 0.5;
    translate([0,0,THICKNESS])
    union(){
    linear_extrude(height)
    text("project-boxy", halign="center", valign="bottom", size=size);
    linear_extrude(height)
    text("@ GitHub", halign="center", valign="top", size=size);
    }
}

//Complete lid
module lid(){
    difference(){
        lid_base(EXTERIOR_WIDTH/2-LID_STANDOFF_DIA/2,EXTERIOR_HEIGHT/2-LID_STANDOFF_DIA/2);
        lid_mounting_holes();
    }
    if(LID_LIP){
    translate([0,0,LID_THICKNESS])   
    difference(){
        lid_lip(EXTERIOR_WIDTH/2-LID_STANDOFF_DIA/2,EXTERIOR_HEIGHT/2-LID_STANDOFF_DIA/2,LID_LIP_TOLERANCE + THICKNESS);
        lid_lip(EXTERIOR_WIDTH/2-LID_STANDOFF_DIA/2,EXTERIOR_HEIGHT/2-LID_STANDOFF_DIA/2,LID_LIP_TOLERANCE + THICKNESS + LID_LIP_WIDTH);
    }
    }
}

module box(){
    //PCB standoffs
    if(BOARD_STANDOFFS){
        translate([BOARD_STANDOFFS_OFFSET_WIDTH,BOARD_STANDOFFS_OFFSET_HEIGHT,0])
        board_standoffs();
    }

    //Holes for the lid
    lid_standoff(EXTERIOR_WIDTH/2-LID_STANDOFF_DIA/2,EXTERIOR_HEIGHT/2-LID_STANDOFF_DIA/2);

    difference(){
        //Main body of the box
        difference(){
            rounded_rect(EXTERIOR_WIDTH,EXTERIOR_HEIGHT,EXTERIOR_DEPTH, CHAMFER_RADIUS, res=EXTERIOR_CHAMFER_RES);
            translate([0,0,THICKNESS])
            rounded_rect(EXTERIOR_WIDTH-THICKNESS*2,EXTERIOR_HEIGHT-THICKNESS*2,EXTERIOR_DEPTH, CHAMFER_RADIUS, res=EXTERIOR_CHAMFER_RES);
        }
        union(){
            //Cutouts for mounting panel mounted devices
            box_mounting_holes();
            arduino_uno_R3(cuts=true);
        }
    }
    project_name();
    if (BOX_CHAMFER_DIA > 0){
        //chamfer around the interior of the main body of the box, not including standoffs.
        box_chamfers(BOX_CHAMFER_DIA);
        //Chamfers around the standoffs for the lid.
        lid_standoff_chamfers(BOX_CHAMFER_DIA,EXTERIOR_WIDTH/2-LID_STANDOFF_DIA/2,EXTERIOR_HEIGHT/2-LID_STANDOFF_DIA/2);
    }
    
    arduino_uno_R3();
    
}

if (BOX && LID){
    displacement = EXTERIOR_WIDTH + PART_SPACING;
    translate([displacement/2,0,0])
    lid();
    translate([-displacement/2,0,0])
    box();
}else if (LID){
    lid();
}else if(BOX){
    box();
}

