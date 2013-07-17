import oscP5.*;
import netP5.*;

OscP5 oscP5;
PImage img;
//String datapath = dataPath("");

void setup() {
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,3333);
  
  /* spectrograph */
  textureMode(NORMAL);
  size(1280, 720, P2D);
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

}

/*
void parseTUIO(OscMessage theOscMessage){
  
}
void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage 
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
  // check if theOscMessage has the address pattern we are looking for.   
  if(theOscMessage.checkAddrPattern("/test")==true) {
    // check if the typetag is the right one. 
    if(theOscMessage.checkTypetag("ifs")) {
      // parse theOscMessage and extract the values from the osc message arguments. 
      int firstValue = theOscMessage.get(0).intValue();  // get the first osc argument
      float secondValue = theOscMessage.get(1).floatValue(); // get the second osc argument
      String thirdValue = theOscMessage.get(2).stringValue(); // get the third osc argument
      print("### received an osc message /test with typetag ifs.");
      println(" values: "+firstValue+", "+secondValue+", "+thirdValue);
      return;
    }
  }
}*/
