PImage img;
String datapath = dataPath("images/squid.png");

void setup() {
  size(1280, 720);
  img = loadImage("spectrogram.png");
}


void draw() {
  image(img, 0, 0);
  if (mousePressed) {
    fill(0);
  } else {
    fill(255);
  }
  ellipse(mouseX, mouseY, 80, 80);
}

