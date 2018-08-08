class Earth {
  PShape earth;
  PImage earth_img;
  float x, y, z;

  Earth(float x_, float y_, float z_) {  
    x = x_; 
    y = y_; 
    z = z_;
    earth = createShape(SPHERE, 300);
    earth_img = loadImage("img/earth.jpg");
    earth.setStrokeWeight(0);
    earth.setTexture(earth_img);
  }

  void disp() {

    pushMatrix();
    pushStyle();
    sphereDetail(20);
    translate(x, y, z);
    rotateY(map(mouseY, 0, height, 0, TWO_PI));
    rotateX(map(mouseX, 0, width, 0, TWO_PI));
    //texture(earth_img);
    shape(earth);
    popStyle();
    popMatrix();
  }
}


class Lamp {
  
  Lamp() {}

void disp(int x, int y, int z, boolean status) {
  // x, y z define the base location of the lamp
  pushMatrix();
  pushStyle();
  sphereDetail(10);
  strokeWeight(0);
  fill(35, 30, 30);
  translate(x, y, z);
  cylinder(12, 6, 25, 15);
  translate(0, 28, 0);
  sphere(6);
  cylinder(4, 4, 130, 15);
  translate(0, 130, 0);
  pushStyle();
  fill(190);
  if (status)
    emissive(255);
  sphere(10);
  translate(0, 6, 0);
  popStyle();
  cylinder(18, 4, 8, 15);
  if (status) {
    //noLights();
    //ambientLight(150, 150, 195);
    pointLight(225, 225, 225, 0, -1, 0);
  }
  translate(0, 6, 0);
  sphere(6);
  popStyle();
  popMatrix();
}}

class Rocks {
  Rocks () {
  }

  void disp(float x, float y, float z) {
    pushStyle();
    pushMatrix();

    shininess(-0.2);
    emissive(15, 10, 20);
    sphereDetail(5);
    strokeWeight(0);

    translate(x, y, z);
    fill(60, 22, 28);
    sphere(70);

    translate(35, 10, 40);
    fill(50, 28, 22);
    sphere(45);

    translate(-15, 10, 40);
    sphereDetail(4);
    sphere(55);

    translate(-70, -40, 20);
    sphere(60);

    translate(-40, 30, 40);
    sphereDetail(5);
    sphere(30);

    popMatrix();
    popStyle();
  }
}