int halfWidth, halfHeight;
int[] bumpmap;
PVector[] normals;
float[] light1, light2, light3;
float[] tmp1, tmp2, tmp3;
final int FPS = 60;

PImage img;

void setup(){
  frameRate(FPS);
  size(640,360);
  //size(1920,1080);
  
  halfWidth = width/2;
  halfHeight = height/2;
  
  //img = loadImage("header.png");
  img = loadImage("what_have_i_done.png");
  img.loadPixels();
  bumpmap = new int[width*height];
  normals = new PVector[width*height];
  light1 = new float[width*height];
  light2 = new float[width*height];
  light3 = new float[width*height];
  tmp1 = new float[width*height];
  tmp2 = new float[width*height];
  tmp3 = new float[width*height];
  loadPixels();
  
  createBump();
  
  thread("updateLightmap1");
  thread("updateLightmap2");
  thread("updateLightmap3");
}

void createBump(){
  PVector va = new PVector(),
          vb = new PVector();
  
  for(int y=0; y<height; y++){
    for(int x=0; x<width; x++){
      bumpmap[y*width+x] = ( (img.pixels[y*width+x] & 0xff) + 
                             (img.pixels[y*width+x] >> 8 & 0xff) +
                             (img.pixels[y*width+x] >> 16 & 0xff) ) / 3;
    }
  }
  
  for(int i=0; i<bumpmap.length; ++i){
    int i1 = i-4,
        i2 = i+4,
        j1 = i-width*4,
        j2 = i+width*4;
      
    va.set(40, 0, bumpmap[i2<bumpmap.length ? i2 : i] - bumpmap[i1>0 ? i1 : i]);
    vb.set(0, 40, bumpmap[j2<bumpmap.length ? j2 : i] - bumpmap[j1>0 ? j1 : i]);
    normals[i] = va.cross(vb).normalize();
  };
}

float mInversePI = 1 / PI;
float brightness = 0.7;
float falloff = 150;
color light1Col = color(255,64,64);
color light2Col = color(64,64, 255);
color light3Col = color(64,255,64);
float lightBrightness = 1.2;
float colorDivider = 1/256.0;
float mls;

void draw(){
  mls = millis();
  int dy = 0;
  
  for(int y=0; y<height; y++){
    dy = y*width;
    for(int x=0; x<width; x++){
      int r = 0;
      int g = 0;
      int b = 0;
      int col = 0xffffffff;
      
      r += (light1Col >> 16 & 0xff) * light1[dy+x];
      g += (light1Col >> 8 & 0xff) * light1[dy+x];
      b += (light1Col & 0xff) * light1[dy+x];
      
      r += (light2Col >> 16 & 0xff) * light2[dy+x];
      g += (light2Col >> 8 & 0xff) * light2[dy+x];
      b += (light2Col & 0xff) * light2[dy+x];
      
      r += (light3Col >> 16 & 0xff) * light3[dy+x];
      g += (light3Col >> 8 & 0xff) * light3[dy+x];
      b += (light3Col & 0xff) * light3[dy+x];
      
      r = min(255, int( ((col >> 16 & 0xff) * r) * colorDivider ));
      g = min(255, int( ((col >> 8 & 0xff) * g) * colorDivider ));
      b = min(255, int( ((col & 0xff) * b) * colorDivider ));
      
      int c = b + (g << 8) + (r << 16) + (0xff << 24);
      
      drawPixel(x,y,c,1);
    }
  }
  
  updatePixels();
  
  //text(frameRate, 20, 20);
  
  //println(frameRate);
}

void drawPixel(int x, int y, int col, int size){
  //if(size == 1){
    pixels[y*width+x] = col;
  //}
  //else {
  //  for(int dy=0; dy<size; ++dy){
  //    for(int dx=0; dx<size; ++dx){
  //      pixels[(y+dy)*width+x+dx] = col;
  //    }
  //  }
  //}
}

boolean onCanvas(int i){
  return i>0 && i<pixels.length;
}

void updateLightmap1(){
  while(true){
    int start = millis();
    PVector l = new PVector( 
                             (cos(start*0.001))*halfWidth + halfWidth, 
                             (sin(start*0.0009))*halfHeight + halfHeight, 
                             180 + sin(start*0.0008) * 40);
    updateLightmap(l, tmp1);
    flushLightmap(tmp1, light1);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
}
void updateLightmap2(){
  while(true){
    int start = millis();
    PVector l = new PVector( 
                            (cos((start+10000)*0.0012))*halfWidth + halfWidth, 
                            (sin((start+10000)*0.00093))*halfHeight + halfHeight, 
                            180 + sin((start+2342)*0.0007) * 40);
    updateLightmap(l, tmp2);
    flushLightmap(tmp2, light2);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
  
}
void updateLightmap3(){
  while(true){
    int start = millis();
    PVector l = new PVector( 
                            (cos((start+20000)*0.0013))*halfWidth + halfWidth, 
                            (sin((start+20000)*0.00091))*halfHeight + halfHeight, 
                            180 + sin((start+5324)*0.0006) * 40);
    updateLightmap(l, tmp3);
    flushLightmap(tmp3, light3);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
}

void updateLightmap(PVector lpos, float[] lmap){
  int dy = 0;
  PVector thispixel = new PVector(), lightDiff = new PVector();
  float brightness = 0;
    
  for(int y=0; y<height; y++){
    dy = y*width;
    for(int x=0; x<width; x++){
      thispixel.set(x, y, (img.pixels[dy+x] & 0xff) * colorDivider * 100);
      lightDiff.set(thispixel.x - lpos.x, thispixel.y - lpos.y, thispixel.z - lpos.z);
      brightness = falloff/lightDiff.mag();
      brightness *= brightness * lightBrightness;
      lmap[dy+x] = atan2(lightDiff.cross(normals[dy+x]).mag(), normals[dy+x].dot(lightDiff)) * mInversePI * brightness;
    }
  }
}

void flushLightmap1(){
  flushLightmap(tmp1, light1);
}
void flushLightmap2(){
  flushLightmap(tmp2, light2);
}
void flushLightmap3(){
  flushLightmap(tmp3, light3);
}

void flushLightmap(float[] source, float[] target){
  for(int i=0; i<source.length; i++){
    target[i] = source[i];
  }
}
