import oscP5.*;
import netP5.*;

OscP5 oscP5;
PImage img;
//String datapath = dataPath("");
int port;
int n_bpbands_total;
int n_steps;
float duration;
float pollrate;

void setup() {
  //This init has to come before the OSC stuff, of the latter gets initialized twice
  size(1280, 720, P2D);
  /* start oscP5, listening for incoming messages at port 3335 */
  //port = int(random(1024, 20480));
  port = 3334;
  oscP5 = new OscP5(this, port);
  /* spectrograph */
  textureMode(NORMAL);
  img = loadImage("spectrogram.png");
  img.loadPixels();
  beginShape();
  texture(img);
  vertex(0, 0, 0, 0);
  vertex(1280, 0, 1, 0);
  vertex(1280, 720, 1, 1);
  vertex(0, 720, 0, 1);
  endShape();
}

void draw() {
  //background(0);  
}

void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage 
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  // check if theOscMessage has the address pattern we are looking for.   
  if(theOscMessage.checkAddrPattern("/viz/init")==true) {
      // parse theOscMessage and extract the values from the osc message arguments.
      // n_bpbands_total, n_steps, duration, pollrate
      n_bpbands_total = theOscMessage.get(0).intValue();  // get the first osc argument
      n_steps = theOscMessage.get(1).intValue(); // get the second osc argument
      duration = theOscMessage.get(2).floatValue(); // get the third osc argument
      pollrate = theOscMessage.get(3).floatValue(); // get the third osc argument
      print("## received an init message /test with typetag ifs.");
      println(" values: "+n_bpbands_total+", "+n_steps+", "+duration+", "+pollrate);
      return;
  }
}
