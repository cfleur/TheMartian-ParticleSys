class ParticleSystem {
  ArrayList<Particle> particleList;
  float size;
  Particle particle;

  ParticleSystem() {
    particleList = new ArrayList<Particle>();
  }

  void addParticle(float size_) {
    size = size_;
    particleList.add(new Particle(size, new PVector(random(-100, 100), 0, random(-100, 100))));
  }

  void addParticleCube(float size_) {
    size = size_;
    particleList.add(new ParticleCube(size, new PVector(random(-100, 100), 0, random(-100, 100))));
  }

  void addForce(PVector force) {
    for (Particle particle : particleList)
      particle.addForce(force);
  }
  
  void fleefrombody(PVector body){
      for (Particle particle : particleList)
        particle.fleefrombody(body);   
  }


  void startSys() {
    for (int i = 0; i < particleList.size(); i++) {
      Particle particle = particleList.get(i);
      particle.updateParticle();
      particle.drawParticle();

      if (particle.livesOver() == true) {
        //println(" life over. index =  ", i);
        particleList.remove(i);
        if (i > 0)
          i--;
        //println("reset index = ", i);
        //println("list length = ", particleList.size());
      }
    }
  }
}