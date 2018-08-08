class MocapInstance {   
  Mocap mocap;
  int currentFrame, firstFrame, lastFrame;
  float[] translation;
  float scl, strkWgt;
  color clr;

  MocapInstance (Mocap mocap1, int startingFrame, float[] transl, float scl1, color clr1, float strkWgt1) {
    mocap = mocap1;
    currentFrame = startingFrame;
    firstFrame = startingFrame;
    lastFrame = startingFrame-1;   
    translation = transl;
    scl = scl1;
    clr = clr1;
    strkWgt = strkWgt1;
  }

  void drawMocap() {
    pushMatrix();
    pushStyle();
    stroke(clr);
    strokeWeight(strkWgt);
    translate(translation[0], translation[1], translation[2]);
    scale(scl);
    int countEnds = 0;

    for (Joint itJ : mocap.joints) {
      //println(itJ.name + "!");

      /* 
       // IF WE FIX THE BUG (STRG+F for "#bug"), WE FIND THE ENSITE WITH THIS SYNTAX
       
       if (itJ.name.toString().equals("EndSiteHead")) {
       println("Torso");
       fill(255, 0, 0);
       } else if (itJ.name.toString().equals("EndSiteRightWrist")) {
       println("Right arm + head");
       fill(0, 255, 0);
       } else if (itJ.name.toString().equals("EndSiteLeftWrist")) {
       println("Left arm + right hand");
       fill(255, 255, 255);
       } else if (itJ.name.toString().equals("EndSiteRightToe")) {
       println("Right leg");
       fill(0, 255, 255);
       } else if (itJ.name.toString().equals("EndSiteLeftToe")) {
       println("Left leg");
       fill(0, 255, 255);
       }
       */

      // Add force away from body to particles
      PVector point = new PVector(itJ.parent.position.get(currentFrame).x + translation[0], itJ.parent.position.get(currentFrame).y + translation[1], itJ.parent.position.get(currentFrame).z + translation[2]);
      particlesys0.fleefrombody(point);
      particlesys1.fleefrombody(point);

      // --- Draw body
      PVector joint = new PVector(itJ.position.get(currentFrame).x, itJ.position.get(currentFrame).y, itJ.position.get(currentFrame).z);
      PVector parent = new PVector(itJ.parent.position.get(currentFrame).x, itJ.parent.position.get(currentFrame).y, itJ.parent.position.get(currentFrame).z);
      float h = parent.dist(joint); // NORM parent and joint
      int w = 5; // cylinder size
      int sides = 7; // number of faces
      float angle;
      float[] x = new float[sides+1];
      float[] z = new float[sides+1];

      // Assign colours to rings
      if (itJ.name.toString().equals("EndSitenull")) {
        countEnds++;
        //println(countEnds);
      }
      if (countEnds == 0) {
        fill(255, 0, 0);
      } else if (countEnds == 1) {
        fill(0, 255, 0);
      } else if (countEnds == 2) {
        fill(255, 255, 255);
      } else if (countEnds == 3) {
        fill(0, 255, 255);
      } else if (countEnds == 4) {
        fill(0, 255, 255);
      } else
        fill(0);

      pushMatrix();
      translate(parent.x, parent.y, parent.z);

      //get the x and z position on a circle for all the sides
      for (int i=0; i < x.length; i++) {
        angle = TWO_PI / (sides) * i;
        x[i] = (sin(angle) * w);
        z[i] = (cos(angle) * w);
      }
      //draw the bottom of the cylinder
      beginShape(TRIANGLE_FAN);
      vertex(0, 0, 0);

      for (int i=0; i < x.length; i++) {
        vertex(x[i], 0, z[i]);
      }
      endShape();
      popMatrix();

      pushStyle();
      stroke(10, 30, 25);
      strokeCap(ROUND);
      strokeWeight(15);
      line(itJ.position.get(currentFrame).x, 
        itJ.position.get(currentFrame).y, 
        itJ.position.get(currentFrame).z, 
        itJ.parent.position.get(currentFrame).x, 
        itJ.parent.position.get(currentFrame).y, 
        itJ.parent.position.get(currentFrame).z);
      popStyle();
    }

    popStyle();
    popMatrix();
    currentFrame = (currentFrame+1) % (mocap.frameNumber);
    if (currentFrame==lastFrame+1) currentFrame = firstFrame;
  }
}


class Mocap {
  float frmRate;
  int frameNumber;
  ArrayList<Joint> joints = new ArrayList<Joint>();

  Mocap (String fileName) {
    String[] lines = loadStrings(fileName);
    float frameTime;
    int readMotion = 0;
    int lineMotion = 0;
    Joint currentParent = new Joint();

    for (int i=0; i<lines.length; i++) {

      //--- Read hierarchy --- 
      String[] words = splitTokens(lines[i], " \t");

      //list joints, with parent
      if (words[0].equals("ROOT")||words[0].equals("JOINT")||words[0].equals("End")) {
        Joint joint = new Joint(); 
        joints.add(joint); // #bug THIS LINE IS BAD. We should move it to the bottom of this if-clause, then the EndSiteXXX will work :) 
        if (words[0].equals("End")) {
          joint.name = "EndSite"+((Joint)joints.get(joints.size()-1)).name;
          joint.isEndSite = 1;
        } else joint.name = words[1];
        if (words[0].equals("ROOT")) {
          joint.isRoot = 1;
          currentParent = joint;
        }
        joint.parent = currentParent;
      }

      //find parent
      if (words[0].equals("{")) {
        currentParent = (Joint)joints.get(joints.size()-1);
      }
      if (words[0].equals("}")) {
        currentParent = currentParent.parent;
      }

      //offset
      if (words[0].equals("OFFSET")) {
        joints.get(joints.size()-1).offset.x = float(words[1]);
        joints.get(joints.size()-1).offset.y = float(words[2]);
        joints.get(joints.size()-1).offset.z = float(words[3]);
      }

      //order of rotations
      if (words[0].equals("CHANNELS")) {
        joints.get(joints.size()-1).rotationChannels[0] = words[words.length-3];
        joints.get(joints.size()-1).rotationChannels[1] = words[words.length-2];
        joints.get(joints.size()-1).rotationChannels[2] = words[words.length-1];
      }

      if (words[0].equals("MOTION")) {
        readMotion = 1;
        lineMotion = i;
      }

      if (words[0].equals("Frames:"))
        frameNumber = int(words[1]);

      if (words[0].equals("Frame") && words[1].equals("Time:")) {
        frameTime = float(words[2]);
        frmRate = round(1000./frameTime)/1000.;
      }

      //--- Read motion, compute positions ---   
      if (readMotion==1 && i>lineMotion+2) {

        //motion data
        PVector RotRelativPos = new PVector();
        int iMotionData = 3;// number of data points read, skip root position      
        for (Joint itJ : joints) {
          if (itJ.isEndSite==0) {// skip end sites
            float[][] currentTransMat = {{1., 0., 0.}, {0., 1., 0.}, {0., 0., 1.}};
            //The transformation matrix is the (right-)product
            //of transformations specified by CHANNELS
            for (int iC=0; iC<itJ.rotationChannels.length; iC++) {
              currentTransMat = multMat(currentTransMat, 
                makeTransMat(float(words[iMotionData]), 
                itJ.rotationChannels[iC]));
              iMotionData++;
            }
            if (itJ.isRoot==1) {//root has no parent:
              //transformation matrix is read directly
              itJ.transMat = currentTransMat;
            } else {//other joints:
              //transformation matrix is obtained by right-applying
              //the current transformation to the transMat of parent
              itJ.transMat = multMat(itJ.parent.transMat, currentTransMat);
            }
          }

          //positions
          if (itJ.isRoot==1) {//root: position read directly + offset
            RotRelativPos.set(float(words[0]), float(words[1]), float(words[2]));
            RotRelativPos.add(itJ.offset);
          } else {//other joints:
            //apply trasnformation matrix from parent on offset
            RotRelativPos = applyMatPVect(itJ.parent.transMat, itJ.offset);
            //add transformed offset to parent position
            RotRelativPos.add(itJ.parent.position.get(itJ.parent.position.size()-1));
          }
          //store position
          itJ.position.add(RotRelativPos);
        }
      }
    }
  }
}

class Joint {
  String name;
  int isRoot = 0;
  int isEndSite = 0;
  Joint parent;
  PVector offset = new PVector();
  //transformation types (CHANNELS):
  String[] rotationChannels = new String[3];
  //current transformation matrix applied to this joint's children:
  float[][] transMat = {{1., 0., 0.}, {0., 1., 0.}, {0., 0., 1.}};
  //list of PVector, xyz position at each frame:
  ArrayList<PVector> position = new ArrayList<PVector>();
}