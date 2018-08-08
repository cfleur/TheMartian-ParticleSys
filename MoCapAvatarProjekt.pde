import peasy.*;
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.processing.*;

// Reads, processes, and displays motion capture BVH files (.bvh)
//
// Assumes there's only one hierarchy per file.
// Assumes channels: root: 3 positions (in that order: X,Y,Z) + 3 rotations (XYZ in any order),
//                   joints: 3 rotations (XYZ in any order),
//                   end sites: none.
// ** Joint translations are not supported! **
//
// A collection of BVH's can be found at http://www.cgspeed.com/ or http://www.motioncapturedata.com
//      (any version, MotionBuilder-, Max-, or Daz-friendly, will work;
//       notice that the latter seems to have a different scale).
//
// Based on mocapBVH from stefanG (with some simplifications): http://www.openprocessing.org/sketch/78767
// Display and overall program structure taken (with slight modifications)
//       from roxstomp's mocap1: http://www.openprocessing.org/sketch/1964
// Some inspiration (joint's transformation matrix) drawn from Bruce Hahne's BVHplay:
//       https://sites.google.com/a/cgspeed.com/cgspeed/bvhplay
//
// In a nut-shell:
// - a Joint has a set of positions;
// - a Mocap is a set of joints;
// - a MocapInstance draws a Mocap, and specifies how.
//
// Computing of positions:
// Except for the root, joints' positions are not directly given in a BVH file.
// Instead, a transformation specified by a joint's CHANNELS are applied to all 
// its descendants. This can be a composition of translation and rotation, though
// in this program only rotations are supported.
// The transfomations are applied to the joints' offsets, so as to produce the
// desired pose at each frame.
// Example: a linear hierarchy with four joints: j1 (root), j2, j3, j4 (end site);
//          each has an offset (zero-pose): 3-vectors off1, off2, off3, off4;
//          the root has a position channel: 3-vector posR;
//          all except the end site have rotation channels: for each joint, 3 angles
//                define a rotation R (which can be represented as a 3x3 matrix);
//          the joints' positions are then:
//                pos1 = off1 + posR;
//                pos2 = R1.off2 + pos1
//                pos3 = R1.R2.off2 + pos2
//                pos4 = R1.R2.R3.off2 + pos3
//          (The root position posR and the angles defining R1, R2, and R3, form the data
//                given at each frame.)


MocapInstance mocapinst;
ToxiclibsSupport render;
ParticleSystem particlesys0, particlesys1;

// ------- Camera -----
PeasyCam cam;
CameraState camReset;
boolean resetCam = false;

// ------- Terrain -----
int SCALE = 20; // Scales the grid
float GROUNDLEVEL = -2;

// Terrain ground
Mesh3D groundMesh;
Terrain ground;
float groundHeight = 200;
int groundSize = 56; // Grid size, even number

// Terrain water
Mesh3D waterMesh;
Terrain water;
float waterHeight = 50;
int waterSize = 18; // Grid size, even number
PImage water_img;

// Lamp
boolean lampOn = false;

Earth earth;
Rocks rocks1, rocks2;
Lamp lamp1, lamp2, lamp3, lamp4;

void setup () {
  //--- Display --- 
  size(800, 600, P3D);
  frameRate(75); 
  smooth();

  //--- Camera ---
  cam = new PeasyCam(this, 0, 0, 0, 650);
  cam.rotateY(PI*3/2);
  cam.rotateX(PI/12);
  //cam.rotateZ(PI/8);
  cam.setMinimumDistance(200);
  cam.setMaximumDistance(750);
  cam.setSuppressRollRotationMode();
  camReset = cam.getState();

  // --- Graphics ---
  render = new ToxiclibsSupport(this);

  //--- Mootion captures ---
  Mocap mocap1 = new Mocap("Avatar-006#My MVN System.bvh");// found at http://www.motioncapturedata.com
  //--- To draw mocaps, specify:
  //which mocap; the time offset (starting frame); the space offset (translation); the scale; the color; the stroke weight. 
  mocapinst = new MocapInstance(mocap1, 0, new float[] {0., -20, -100.}, 0.9, color(0), 3);

  // --- Terrain ---
  water = new Terrain(waterSize, waterSize, SCALE);
  ground = new Terrain(groundSize, groundSize, SCALE);
  water_img = loadImage("img/water-1018808_640.jpg");

  // --- Particles ---
  particlesys0 = new ParticleSystem();
  particlesys1 = new ParticleSystem();

  // --- Objects ---
  earth = new Earth(700, 500, 1000);
  rocks1 = new Rocks();
  rocks2 = new Rocks();
  lamp1 = new Lamp();
  lamp2 = new Lamp();
  lamp3 = new Lamp();
  lamp4 = new Lamp();
}

void draw() {
  if (resetCam) {
    cam.setState(camReset, 1000);
    resetCam = false;
  }

  background(60, 40, 60);
  lights();

  rotateX(PI);
  
  // Uncomment to see axes
  //drawAxes();

  rotateY(PI/6);

  earth.disp();
  lamp1.disp(200, 12, -200, lampOn);
  lamp2.disp(-370, -70, -100, lampOn);
  lamp3.disp(110, 23, -400, lampOn);
  lamp4.disp(-160, -15, 160, lampOn);

  //antig is now inside the particle
  PVector antig = new PVector(random(-0.02, 0.02), 0.01, random(-0.02, 0.02));
  // JUST TEMP FOR TESTING THE PARTICLE BEHAVIOR
  particlesys0.addForce(antig); // spheres
  particlesys1.addForce(antig); // cubes 

  if (keyPressed) {
    particlesys0.addParticleCube(random(2, 5));
    PVector wind = new PVector(random(-0.2, 0.17), random(0.02), random(-0.2, 0.17));
    particlesys0.addForce(wind); // spheres
    particlesys1.addForce(wind); // cubes
  } 

  mocapinst.drawMocap();

  rocks1.disp(120, -10, 120);
  pushMatrix();
  scale(1.2);
  rotateX(PI);
  rotateX(PI/15);
  rocks2.disp(-160, 30, -55);
  popMatrix();

  pushMatrix();
  rotateX(PI); 
  rotateY(PI);
  drawGround(ground, render, groundSize, groundHeight, 0.08);
  drawWater(water, render, waterSize, waterHeight, 0.2);
  popMatrix();

  particlesys0.addParticle(random(2, 5));
  particlesys0.startSys();
  particlesys1.addParticle(random(2, 5));
  particlesys1.startSys(); 

  cam.beginHUD();
  displayUI();
  cam.endHUD();
}

//-------------------------------------
// Functions --------------------------
//-------------------------------------

// --- Debugging ---
void drawAxes() {
  stroke(255, 0, 0);
  line(-300, 0, 0, 300, 0, 0);
  text("+x", 300, 0, 0);
  text("-x", -330, 0, 0);
  stroke(0, 255, 0);
  line(0, -300, 0, 0, 300, 0);
  text("+y", 0, 330, 0);
  text("-y", 0, -300, 0);
  stroke(0, 0, 255);
  line(0, 0, -300, 0, 0, 300);
  text("+z", 0, 0, 330);
  text("-z", 0, 0, -300);
}

// --- Display non-moving parts (UI) ---
void displayUI() {
  PShape timeBox, resetBox, UIinfo;
  int sec = millis()/1000;
  int min = millis()/60000;
  if (sec >= 60)
    sec -= 60*min;

  // Draw time box and text
  pushStyle();
  textSize(20);
  strokeWeight(1);
  stroke(255);
  fill(15, 150);
  timeBox = createShape();
  timeBox.beginShape();
  timeBox.vertex(width-10, height-10, 0);
  timeBox.vertex(width-10, height-50, 0);
  timeBox.vertex(width-140, height-50, 0);
  timeBox.vertex(width-140, height-10, 0);
  timeBox.endShape(CLOSE);
  shape(timeBox);

  UIinfo = createShape();
  UIinfo.beginShape();
  UIinfo.noStroke();
  UIinfo.vertex(width-310, height-10, 0);
  UIinfo.vertex(width-310, height-100, 0);
  UIinfo.vertex(width-790, height-100, 0);
  UIinfo.vertex(width-790, height-10, 0);
  UIinfo.endShape(CLOSE);
  shape(UIinfo);

  if (mouseX >= width-300 && mouseX <= width-150 && mouseY >= height-50 && mouseY <= height-10) {
    fill(50);
  }

  resetBox = createShape();
  resetBox.beginShape();
  resetBox.vertex(width-150, height-10, 0);
  resetBox.vertex(width-150, height-50, 0);
  resetBox.vertex(width-300, height-50, 0);
  resetBox.vertex(width-300, height-10, 0);
  resetBox.endShape(CLOSE);
  shape(resetBox);

  fill(0, 200, 0);
  if (sec < 10)
    text("Time "+min+":0"+sec, width-130, height-25);
  else
    text("Time "+min+":"+sec, width-130, height-25);

  fill(225);
  text("Reset camera", width-290, height-25);
  textSize(16);
  fill(0, 255, 0);
  text("Interactivity", width-780, height-75);
  fill(225);
  text("UP key= lights on, DOWN key= lights off\nclick-drag-scroll= camera, hold any key= wind+cubes", width-780, height-50);

  popStyle();
}
void mouseClicked() {
  if (mouseX >= width-300 && mouseX <= width-150 && mouseY >= height-50 && mouseY <= height-10)
    resetCam = true;
}

// ----- Key status -----
void keyPressed() {
  if (keyCode == UP) {
    lampOn = true;
  }
  if (keyCode == DOWN) {
    lampOn = false;
  } else {
  }
}

// --- Draw water ---
void drawWater(Terrain terrain, ToxiclibsSupport gfx, int size, float height_, float diff) {
  float [][] elevation = elevationInit(height_, size, diff);
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      terrain.setHeightAtCell(i, j, elevation[i][j]);
      if (i < 1 || i > size-2) terrain.setHeightAtCell(i, j, GROUNDLEVEL);
      if (j < 1 || j > size-2) terrain.setHeightAtCell(i, j, GROUNDLEVEL);
    }
  }

  // Water texture
  PShape shape; 
  int sizeShape = size*SCALE;
  textureMode(NORMAL);
  pushStyle();
  shape = createShape(); 
  shape.setTexture(water_img);
  shape.beginShape();
  shape.noStroke();
  texture(water_img);
  shape.vertex(-sizeShape/2, 0, -sizeShape/2, 0, 0);
  shape.vertex(-sizeShape/2, 0, (sizeShape/2)-SCALE, 0, 1);
  shape.vertex((sizeShape/2)-SCALE, 0, (sizeShape/2)-SCALE, 1, 1);
  shape.vertex((sizeShape/2)-SCALE, 0, -(sizeShape/2), 1, 0);
  shape.vertex(-sizeShape/2, 0, -sizeShape/2, 0, 0);
  shape.vertex(-(sizeShape/2)+SCALE, height_*0.7, -(sizeShape/2)+SCALE, 0, 1);
  shape.vertex(-(sizeShape/2)+SCALE, height_*0.7, (sizeShape/2)-2*SCALE, 1, 1);
  shape.vertex((sizeShape/2)-2*SCALE, height_*0.7, (sizeShape/2)-2*SCALE, 1, 0);
  shape.vertex((sizeShape/2)-2*SCALE, height_*0.7, -(sizeShape/2)+SCALE, 0, 0);
  shape.vertex(-(sizeShape/2)+SCALE, height_*0.7, -(sizeShape/2)+SCALE, 0, 1);
  // ! Texture in 1st quadran not drawn correctly
  shape.endShape(CLOSE);
  shape.setStrokeWeight(4);
  shape(shape);
  popStyle();

  // Draw water
  waterMesh = terrain.toMesh(height_*0.8);
  pushStyle();
  noStroke();
  fill(0, 160, 200, 175);
  emissive(0, 40, 150);
  shininess(1.0);
  gfx.mesh(waterMesh, false);
  popStyle();
}

// --- Draw ground ---
void drawGround(Terrain terrain, ToxiclibsSupport gfx, int size, float height_, float diff) {
  float [][] elevation = elevationInit(height_, size, diff);
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      terrain.setHeightAtCell(i, j, elevation[i][j]);
      if ((i > waterSize+2 && i < groundSize-waterSize && j > waterSize && j < groundSize-waterSize-1)) 
        terrain.setHeightAtCell(i, j, GROUNDLEVEL);
      if ((i > waterSize+2 && i < groundSize-waterSize-2 && j > waterSize+1 && j < groundSize-waterSize-2)) 
        terrain.setHeightAtCell(i, j, GROUNDLEVEL+waterHeight+1);
    }
  }
  groundMesh = terrain.toMesh(height_*0.8);
  pushStyle();
  noStroke();
  fill(80, 50, 40);
  emissive(55, 15, 30);
  shininess(0.5);
  gfx.mesh(groundMesh, true);

  popStyle();
}

// --- Create elevation matrix ---
float[][] elevationInit(float maxElevation, int size, float diff) {
  float [][] yValues = new float [size][size];
  float variation = maxElevation;// height/depth of mountains (z value)
  //float diff = 0.1; // size of step change in y values
  float waves = 0;
  noiseSeed(2);

  waves += diff;
  float zDiff = waves;
  for (int z = 0; z < size; z++) {
    float xDiff = 0;
    for (int x = 0; x < size; x++) {
      yValues[z][x] = map(noise(xDiff, zDiff), 0, 1, variation, -variation);
      xDiff += diff;
    }
    zDiff += diff;
  }
  return yValues;
}

// --- Cylinder ---
void cylinder(float bottom, float top, float h, int sides) {
  pushMatrix();
  translate(0, h/2, 0);

  float angle;
  float[] x = new float[sides+1];
  float[] z = new float[sides+1];

  float[] x2 = new float[sides+1];
  float[] z2 = new float[sides+1];

  //get the x and z position on a circle for all the sides
  for (int i=0; i < x.length; i++) {
    angle = TWO_PI / (sides) * i;
    x[i] = sin(angle) * bottom;
    z[i] = cos(angle) * bottom;
  }

  for (int i=0; i < x.length; i++) {
    angle = TWO_PI / (sides) * i;
    x2[i] = sin(angle) * top;
    z2[i] = cos(angle) * top;
  }

  //draw the bottom of the cylinder
  beginShape(TRIANGLE_FAN);
  vertex(0, -h/2, 0);

  for (int i=0; i < x.length; i++) {
    vertex(x[i], -h/2, z[i]);
  }
  endShape();

  //draw the center of the cylinder
  beginShape(QUAD_STRIP); 

  for (int i=0; i < x.length; i++) {
    vertex(x[i], -h/2, z[i]);
    vertex(x2[i], h/2, z2[i]);
  }
  endShape();

  //draw the top of the cylinder
  beginShape(TRIANGLE_FAN); 
  vertex(0, h/2, 0);

  for (int i=0; i < x.length; i++) {
    vertex(x2[i], h/2, z2[i]);
  }
  endShape();
  popMatrix();
}

float[][] multMat(float[][] A, float[][] B) {//computes the matrix product AB
  int nA = A.length;
  int nB = B.length;
  int mB = B[0].length;
  float[][] AB = new float[nA][mB];
  for (int i=0; i<nA; i++) {
    for (int k=0; k<mB; k++) {
      if (A[i].length!=nB) {
        println("multMat: matrices A and B have wrong dimensions! Exit.");
        exit();
      }
      AB[i][k] = 0.;
      for (int j=0; j<nB; j++) {
        if (B[j].length!=mB) {
          println("multMat: matrices A and B have wrong dimensions! Exit.");
          exit();
        }
        AB[i][k] += A[i][j]*B[j][k];
      }
    }
  }
  return AB;
}

float[][] makeTransMat(float a, String channel) {
  //produces transformation matrix corresponding to channel, with argument a
  float[][] transMat = {{1., 0., 0.}, {0., 1., 0.}, {0., 0., 1.}};
  if (channel.equals("Xrotation")) {
    transMat[1][1] = cos(radians(a));
    transMat[1][2] = - sin(radians(a));
    transMat[2][1] = sin(radians(a));
    transMat[2][2] = cos(radians(a));
  } else if (channel.equals("Yrotation")) {
    transMat[0][0] = cos(radians(a));
    transMat[0][2] = sin(radians(a));
    transMat[2][0] = - sin(radians(a));
    transMat[2][2] = cos(radians(a));
  } else if (channel.equals("Zrotation")) {
    transMat[0][0] = cos(radians(a));
    transMat[0][1] = - sin(radians(a));
    transMat[1][0] = sin(radians(a));
    transMat[1][1] = cos(radians(a));
  } else {
    println("makeTransMat: unknown channel! Exit.");
    exit();
  }
  return transMat;
}

PVector applyMatPVect(float[][] A, PVector v) {
  //apply (square matrix) A to v (both must have dimension 3)
  for (int i=0; i<A.length; i++) {
    if (v.array().length!=3||A.length!=3||A[i].length!=3) {
      println("applyMatPVect: matrix and/or vector not of dimension 3! Exit.");
      exit();
    }
  }
  PVector Av = new PVector();
  Av.x = A[0][0]*v.x + A[0][1]*v.y + A[0][2]*v.z;
  Av.y = A[1][0]*v.x + A[1][1]*v.y + A[1][2]*v.z;
  Av.z = A[2][0]*v.x + A[2][1]*v.y + A[2][2]*v.z;
  return Av;
}