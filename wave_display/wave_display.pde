
PImage img;
//String datapath = dataPath("");

void setup() {
  textureMode(NORMAL);
  size(1280, 720, P2D);
  img = loadImage("spectrogram.png");
  img.loadPixels();
  beginShape();
  texture(img);
  vertex(0, 0, 0, 0);
  vertex(1280, 0, img.width, 0);
  vertex(1280, 720, img.width, img.height);
  vertex(0, 720, 0, img.height);
  endShape();
}


void draw() {
  //image(img, 0, 0);
  if (mousePressed) {
    fill(0);
  } else {
    fill(255);
  }
  ellipse(mouseX, mouseY, 80, 80);
}

