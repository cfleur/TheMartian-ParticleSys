class ParticleCube extends Particle {

  ParticleCube(float radius_, PVector instanceloc_) {
    super(radius_, instanceloc_);
    PShape cube = createShape(BOX, radius_, radius_, radius_);
    shape = cube;
  }
  //void addForce(PVector force_) {
  //  force = force_;
  //}
}