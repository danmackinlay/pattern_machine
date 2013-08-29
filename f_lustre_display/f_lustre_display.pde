/*TODO:
 */

import oscP5.*;
import netP5.*;
import codeanticode.syphon.*;
import java.util.Properties;

Properties loadCommandLine () {
  Properties props = new Properties();
  //props.setProperty("width", "1280");
  //props.setProperty("height", "720");
  
  for (String arg:args) {
    String[] parsed = arg.split("=", 2);
    if (parsed.length == 2)
      println("parsing");
      println(parsed[0]);
      println(parsed[1]);
      props.setProperty(parsed[0], parsed[1]);
  }
  return props;
}

SyphonServer syphonserver;

OscP5 oscP5;
NetAddress respondAddress;
int listenPort;
int respondPort;

PGraphics canvas;
PImage spectroImg;

boolean ready_for_spectral_data = false;
boolean spectrogram_updated = false;
boolean blobs_updated = false;
int n_bpbands_total;
int n_steps;
float duration;
float pollrate;
float next_step_time;
int next_step_i;
float[] next_bands;

Properties props;
int pxwidth;
int pxheight;

float[] blobX = new float[200]; // we can track 200 blobs. This is enough blobs.
float[] blobY = new float[200];
int n_blobs = 0;

public void init() {

  frame.removeNotify();

  frame.setUndecorated(true);

  frame.addNotify();

  super.init();
}

void setup() {
  props = loadCommandLine();
  pxwidth = int(props.getProperty("width", "1280"));
  pxheight = int(props.getProperty("height", "720"));
  listenPort = int(props.getProperty("listenport", "3334"));
  respondPort = int(props.getProperty("respondport", "3333"));
  //This size init has to come before the OSC stuff, or the latter
  //gets initialized twice without the earlier one getting disposed.
  size(pxwidth, pxheight, P2D);
  canvas = createGraphics(pxwidth, pxheight, P2D); 

  //This explodes (for Syphon?)
  //smooth(4);
  
  syphonserver = new SyphonServer(this, "f_lustre");
  /* start oscP5, listening for incoming messages */
  oscP5 = new OscP5(this, listenPort);
  respondAddress = new NetAddress("127.0.0.1", respondPort);

  spectroImg = loadImage("spectrogram.png");
  
  //Now we can phone home and tell them that we are ready to accept data.
  OscMessage myMessage = new OscMessage("/viz/alive");
  myMessage.add(1); /* add an int to the osc message */
  /* send the message */
  oscP5.send(myMessage, respondAddress);
}

void draw_spectrogram (PGraphics ctx){
  ctx.textureMode(NORMAL);
  ctx.beginShape();
  ctx.texture(spectroImg);
  ctx.vertex(0, 0, 0, 0);
  ctx.vertex(pxwidth, 0, 1, 0);
  ctx.vertex(pxwidth, pxheight, 1, 1);
  ctx.vertex(0, pxheight, 0, 1);
  ctx.endShape();
}

void draw_blobs(PGraphics ctx){
  ctx.ellipseMode(RADIUS);
  ctx.fill(255,0,0);
  for (int i = 0; i < n_blobs; i = i+1) {
    ctx.ellipse(pxwidth*blobX[i], pxheight*(1.0-blobY[i]), 10.0, 10.0);
  }
  //ctx.text(nf(frameCount,0),0,0);
}

void draw() {
  if(frameCount == 1) frame.setLocation(0, 0);
  if (spectrogram_updated|| blobs_updated||frameCount<=1) {
    spectroImg.updatePixels();
    canvas.beginDraw();
    draw_spectrogram(canvas);
    draw_blobs(canvas);
    canvas.endDraw();
    image(canvas, 0, 0);
    syphonserver.sendImage(canvas);
  }
  spectrogram_updated = false;
  blobs_updated = false;
}

void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage
  //print("### received an osc message.");
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //println(" typetag: "+theOscMessage.typetag());
  // All spectral functions are switched by whether we have received the right init info or not:
  if(theOscMessage.checkAddrPattern("/viz/init")==true) {
    // parse theOscMessage and extract the values from the osc message arguments.
    // n_bpbands_total, n_steps, duration, pollrate
    n_bpbands_total = theOscMessage.get(0).intValue();
    n_steps = theOscMessage.get(1).intValue();
    duration = theOscMessage.get(2).floatValue();
    pollrate = theOscMessage.get(3).floatValue();
    //print("## received an init message .");
    //println(" values: "+n_bpbands_total+", "+n_steps+", "+duration+", "+pollrate);
    spectroImg.resize(n_steps,n_bpbands_total);
    spectroImg.loadPixels();
    ready_for_spectral_data=true;
    next_step_time = 0.0;
    next_step_i = -1;
  }  else if(theOscMessage.checkAddrPattern("/viz/stop")==true) {
    //print("## received a stop message .");
    ready_for_spectral_data=false;
  }  else if(theOscMessage.checkAddrPattern("/viz/blobs")==true) {
    //print("## received a blobs message .");
    n_blobs = theOscMessage.typetag().length()/3;
    for (int i = 0; i < n_blobs; i = i+1) {
      int j=i*3;
      // this would return the blob id, not currently used:  theOscMessage.get(j+1).intValue();
      blobX[i] = theOscMessage.get(j+1).floatValue();
      blobY[i] = theOscMessage.get(j+2).floatValue();
    }
    blobs_updated = true;
  } 
  if(ready_for_spectral_data) {
    if(theOscMessage.checkAddrPattern("/viz/step")==true) {
      next_step_time = theOscMessage.get(0).floatValue();
      next_step_i++;
    } else if(theOscMessage.checkAddrPattern("/viz/bands")==true) {
      next_bands = new float[n_bpbands_total];
      for (int i = 0; i < n_bpbands_total; i = i+1) {
        next_bands[i] = theOscMessage.get(i).floatValue();
      }
      for (int i = 0; i < n_bpbands_total; i = i+1) {
        //careful with the fiddly quasi-pointer arithmetic
        //count in rows from top left down
        spectroImg.pixels[next_step_i+n_steps*(n_bpbands_total-i-1)] = color(int(next_bands[i]*256));
      }
      print("## received bands message .");
      print(join(nf(next_bands, 0, 3), ";"));
      spectrogram_updated=true;
    }
  }
}
void dispose() {
  //Now we can phone home and tell them that we are dead.
  OscMessage myMessage = new OscMessage("/viz/alive");
  myMessage.add(0); /* add an int to the osc message */
  /* send the message */
  oscP5.send(myMessage, respondAddress);
}
