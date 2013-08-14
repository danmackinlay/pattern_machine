import oscP5.*;
import netP5.*;
import codeanticode.syphon.*;
/*TODO:
 * parse CLI (ports, dimensions)
   * https://forum.processing.org/topic/use-external-editor-is-gone-in-beta-5-now-what
   * https://forum.processing.org/topic/get-command-line-parameter-from-compiled-sketch
   * http://wiki.processing.org/w/Setting_width/height_dynamically
   * https://code.google.com/p/processing/issues/detail?id=142
 */

///begin workaround from https://forum.processing.org/topic/my-solution-for-processing-2-0-1-syphon
import javax.media.opengl.GL2;
import jsyphon.*;

class SyphonServer2{
  protected JSyphonServer syphon;
  protected GL2 gl;
  protected int[] texID;
  protected int[] syphonFBO;
  
  public SyphonServer2(String name){
    syphon = new JSyphonServer();
    syphon.initWithName(name);
    println("Starting the syphon server:"+name);
    try {
      gl = ((PGraphicsOpenGL)g).pgl.gl.getGL2();
    } catch (javax.media.opengl.GLException e) {
      println("OpenGL 2 not supported!");
    }
    
    texID = new int[1];
    gl.glGenTextures(1, texID, 0);
    gl.glBindTexture(GL2.GL_TEXTURE_RECTANGLE, texID[0]);
    gl.glTexImage2D(GL2.GL_TEXTURE_RECTANGLE, 0, GL2.GL_RGBA8, width, height, 0, GL2.GL_RGBA, GL2.GL_UNSIGNED_BYTE, null);
    
    int[] defaultFBO = new int[1];
    gl.glGetIntegerv(GL2.GL_FRAMEBUFFER_BINDING, defaultFBO, 0);
    
    syphonFBO = new int[1];
    gl.glGenFramebuffers(1, syphonFBO, 0);
    gl.glBindFramebuffer(GL2.GL_FRAMEBUFFER, syphonFBO[0]);
    gl.glFramebufferTexture2D(GL2.GL_FRAMEBUFFER, GL2.GL_COLOR_ATTACHMENT0, GL2.GL_TEXTURE_RECTANGLE, texID[0], 0);
    gl.glBindFramebuffer(GL2.GL_FRAMEBUFFER, defaultFBO[0]);
  }
  
  public void send(){
    int[] defaultFBO = new int[1];
    gl.glGetIntegerv(GL2.GL_FRAMEBUFFER_BINDING, defaultFBO, 0);
    //println("fbo="+defaultFBO[0]);
    
    gl.glBindFramebuffer(GL2.GL_READ_FRAMEBUFFER, defaultFBO[0]);
    gl.glBindFramebuffer(GL2.GL_DRAW_FRAMEBUFFER, syphonFBO[0]);
    gl.glBlitFramebuffer(0, 0, width, height, 
                         0, 0, width, height, 
                         GL2.GL_COLOR_BUFFER_BIT, GL2.GL_LINEAR);
                         
    syphon.publishFrameTexture(texID[0], GL2.GL_TEXTURE_RECTANGLE, 0, 0, width, height, width, height, false);
    gl.glBindFramebuffer(GL2.GL_FRAMEBUFFER, defaultFBO[0]);
  }
  
  public void stop(){
    println("deleting textures");
    gl.glDeleteTextures(1, texID, 0);
    gl.glDeleteFramebuffers(1, syphonFBO, 0);
    if(syphon!=null) {
      println("stopping the syphon server");
      syphon.stop();
    }
  }
}
///end workaround from https://forum.processing.org/topic/my-solution-for-processing-2-0-1-syphon

SyphonServer2 syphonserver;
OscP5 oscP5;
PImage img;
int port;
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

float[] blobX = new float[200]; // we can track 200 blobs. This is enough.
float[] blobY = new float[200];
int n_blobs = 0;

void setup() {
  //This init has to come before the OSC stuff, or the latter gets initialized twice
  size(1280, 720, P2D);
  syphonserver = new SyphonServer2("f_lustre");
  /* start oscP5, listening for incoming messages at port 3334 */
  port = 3334;
  oscP5 = new OscP5(this, port);
  /* spectrograph */
  textureMode(NORMAL);
  ellipseMode(RADIUS);
  img = loadImage("spectrogram.png");
}

void draw_spectrogram (){
  beginShape();
  texture(img);
  vertex(0, 0, 0, 0);
  vertex(1280, 0, 1, 0);
  vertex(1280, 720, 1, 1);
  vertex(0, 720, 0, 1);
  endShape();
}

void draw_blobs(){
  fill(255,0,0);
  for (int i = 0; i < n_blobs; i = i+1) {
    ellipse(1280.0*blobX[i], 720.0*(1.0-blobY[i]), 20.0, 20.0);
  }
}

void draw() {
  if (spectrogram_updated|| blobs_updated) {
    img.updatePixels();
    draw_spectrogram();
    draw_blobs();
    syphonserver.send();
  }
  spectrogram_updated = false;
  blobs_updated = false;
}

void oscEvent(OscMessage theOscMessage) {
  // print the address pattern and the typetag of the received OscMessage
  print("### received an osc message.");
  print(" addrpattern: "+theOscMessage.addrPattern());
  println(" typetag: "+theOscMessage.typetag());
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
    img.resize(n_steps,n_bpbands_total);
    img.loadPixels();
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
        img.pixels[next_step_i+n_steps*(n_bpbands_total-i-1)] = color(int(next_bands[i]*256));
      }
      //print("## received bands message .");
      print(join(nf(next_bands, 0, 3), ";"));
      spectrogram_updated=true;
    }
  }
}
void dispose() {
  syphonserver.stop();
}
