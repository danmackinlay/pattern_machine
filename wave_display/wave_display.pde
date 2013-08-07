import oscP5.*;
import netP5.*;

OscP5 oscP5;
PImage img;
//String datapath = dataPath("");
int port;
boolean ready_for_data = false;
boolean data_updated = false;
int n_bpbands_total;
int n_steps;
float duration;
float pollrate;
float next_step;
float[] next_bands;

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
  
  data_updated = false;
}

void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage 
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  // All other functions are switched by whether we have received the right init info or not:
  if(theOscMessage.checkAddrPattern("/viz/init")==true) {
      // parse theOscMessage and extract the values from the osc message arguments.
      // n_bpbands_total, n_steps, duration, pollrate
      n_bpbands_total = theOscMessage.get(0).intValue(); 
      n_steps = theOscMessage.get(1).intValue();
      duration = theOscMessage.get(2).floatValue();
      pollrate = theOscMessage.get(3).floatValue();
      print("## received an init message .");
      println(" values: "+n_bpbands_total+", "+n_steps+", "+duration+", "+pollrate);
      ready_for_data=true;
      next_step = 0.0;
  }  else if(theOscMessage.checkAddrPattern("/viz/stop")==true) {
      print("## received a stop message .");
      ready_for_data=false;
  }
  if(ready_for_data) {
      if(theOscMessage.checkAddrPattern("/viz/step")==true) {
          next_step = theOscMessage.get(0).floatValue();
      } else if(theOscMessage.checkAddrPattern("/viz/bands")==true) {
          next_bands = new float[n_bpbands_total];
          for (int i = 0; i < n_bpbands_total; i = i+1) {
              next_bands[i] = theOscMessage.get(i).floatValue();
          }
          print(join(nf(next_bands, 0, 3), ";"));
        data_updated=true;
      }
  }
}
