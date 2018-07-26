int halfWidth, halfHeight;
int[] bumpmap;
PVector[] normals;
int ns = 0;
Perlin perlin;

PVector light = new PVector(),
        camera = new PVector(),
        l = new PVector();
PVector va = new PVector(),
        vb = new PVector(), 
        normal = new PVector();

int pixelSize = 2;
int i, x, y;

PImage img;

void setup(){
  size(640,360);
  //size(1920,1080);
  frameRate(30);
  
  halfWidth = width/2;
  halfHeight = height/2;
  
  //img = loadImage("header.png");
  img = loadImage("what_have_i_done.png");
  img.loadPixels();
  bumpmap = new int[width*height+1];
  normals = new PVector[width*height+1];
  loadPixels();
  
  noiseDetail(50,0.4);
  
  perlin = new Perlin();
  
  
  createBump(1);
  
  light.x = width/2.0;
  light.y = height/2.0;
  light.z = 40;
}

void createBump(int seed){
  noiseSeed(seed);
  float increment = 0.01;
  float a = 0, b;
  for(int y=0; y<height; y++){
    a += increment;
    b = 0;
    for(int x=0; x<width; x++){
      b += increment;
      //float noise = perlin.noise2D(a,b,a-b,b-a,1)+0.5;
      float noise = noise(a,b);
      //bumpmap[y*width+x] = int(255 * noise);
      bumpmap[y*width+x] = int((0 * noise + (img.pixels[y*width+x] & 0xff)));
    }
  }
  
  for(i=0; i<bumpmap.length; ++i){
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
float falloff = 100;
color lightCol = color(255,64,64);
color light3Col = color(64,255,64);
float lightBrightness = 1.2;
color mouseCol = color(64,64,255);
float mouseBrightness = 1.2;
color globalIllumination = color(255,255,255);
float globalBrightness = 0;
float colorDivider = 1/255.0;

void draw(){
  int mx = mouseX, my = mouseY, mz = 80;
  int dy = 0;
  int mls = millis();
  PVector l = PVector.add(light, new PVector( (cos(mls*0.001))*halfWidth, (sin(mls*0.0009))*halfHeight, mz));
  PVector l2 = PVector.add(light, new PVector( (cos((mls+10000)*0.0012))*halfWidth, (sin((mls+10000)*0.00093))*halfHeight, mz));
  PVector l3 = PVector.add(light, new PVector( (cos((mls+20000)*0.0013))*halfWidth, (sin((mls+20000)*0.00091))*halfHeight, mz));
  //PVector m = new PVector(mx, my, mz);
  for(y=0; y<height; y+=pixelSize){
    dy = y*width;
    for(x=0; x<width; x+=pixelSize){
      int r = 0;
      int g = 0;
      int b = 0;
      int col = color(255);
      PVector thispixel = new PVector(x, y, (img.pixels[y*width+x] & 0xff) * colorDivider * 100);
      
      
      PVector mouseDiff = PVector.sub(thispixel, l2);
      float b1 = falloff/mouseDiff.mag();
      //b1 *= b1;
      b1 = min(1, b1);
      b1 *= mouseBrightness;
      float a1 = PVector.angleBetween(mouseDiff, normals[dy+x]) * mInversePI * b1;
      r += (mouseCol >> 16 & 0xff) * a1;
      g += (mouseCol >> 8 & 0xff) * a1;
      b += (mouseCol & 0xff) * a1;
      
      
      PVector lightDiff = PVector.sub(thispixel, l);
      float b2 = falloff/lightDiff.mag();
      //b2 *= b2;
      b2 = min(1, b2);
      b2 *= lightBrightness;
      float a2 = PVector.angleBetween(lightDiff, normals[dy+x]) * mInversePI * b2;
      r += (lightCol >> 16 & 0xff) * a2;
      g += (lightCol >> 8 & 0xff) * a2;
      b += (lightCol & 0xff) * a2;
      
      PVector lightDiff3 = PVector.sub(thispixel, l3);
      float b3 = falloff/lightDiff3.mag();
      //b2 *= b2;
      b3 = min(1, b3);
      b3 *= lightBrightness;
      float a3 = PVector.angleBetween(lightDiff3, normals[dy+x]) * mInversePI * b3;
      r += (light3Col >> 16 & 0xff) * a3;
      g += (light3Col >> 8 & 0xff) * a3;
      b += (light3Col & 0xff) * a3;
      
      //r += (globalIllumination >> 16 & 0xff) * globalBrightness;
      //g += (globalIllumination >> 8 & 0xff) * globalBrightness;
      //b += (globalIllumination & 0xff) * globalBrightness;
      
      r = int( ((col >> 16 & 0xff) * r) * colorDivider);
      g = int( ((col >> 8 & 0xff) * g) * colorDivider);
      b = int( ((col & 0xff) * b) * colorDivider);
      
      color c = color(r, g, b); 
      
      drawPixel(x,y,c,pixelSize);
    }
  }
  
  updatePixels();
  
  //text(frameRate, 20, 20);
  
  //println(frameRate);
}

void drawPixel(int x, int y, int col, int size){
  if(size == 1){
    pixels[y*width+x] = col;
  }
  else {
    for(int dy=0; dy<size; ++dy){
      for(int dx=0; dx<size; ++dx){
        pixels[(y+dy)*width+x+dx] = col;
      }
    }
  }
}

boolean onCanvas(int i){
  return i>0 && i<pixels.length;
}
