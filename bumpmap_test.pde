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
  frameRate(60);
  
  img = loadImage("chinese_building.png");
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
      bumpmap[y*width+x] = int((0 * noise + (img.pixels[(y+120)*width+x] & 0xff)));
    }
  }
  
  for(i=0; i<bumpmap.length; ++i){
    int i1 = i-1,
        i2 = i+1,
        j1 = i-width,
        j2 = i+width;
      
    va.set(10, 0, bumpmap[i2<bumpmap.length ? i2 : i] - bumpmap[i1>0 ? i1 : i]);
    vb.set(0, 10, bumpmap[j2<bumpmap.length ? j2 : i] - bumpmap[j1>0 ? j1 : i]);
    normals[i] = va.cross(vb).normalize();
  };
}

float muu = 255 / PI;
float brightness = 0.7;
float falloff = 100;
void draw(){
  int mx = mouseX, my = mouseY, mz = 40;//int((sin(frameCount*0.1)+1)*100);
  int dy = 0;
  PVector l = PVector.add(light, new PVector( (cos(frameCount*0.025))*200, (sin(frameCount*0.02))*200, 0));
  for(y=0; y<height; y+=pixelSize){
    dy = y*width;
    for(x=0; x<width; x+=pixelSize){
      int col = 0;
      PVector thispixel = new PVector(x, y, 0);
      
      PVector mouseDiff = PVector.sub(thispixel, new PVector(mx, my, mz));
      float b1 = falloff/mouseDiff.mag();
      b1 *= b1 * b1;
      b1 = min(b1, brightness);
      float a1 = PVector.angleBetween(mouseDiff, normals[dy+x]);
      if(a1 > 0){
        col += int(a1 * muu * b1);
      }
      
      
      PVector lightDiff = PVector.sub(thispixel, l);
      float b2 = falloff/lightDiff.mag();// PVector.dist(l, thispixel);
      b2 *= b2 * b2;
      b2 = min(b2, brightness);
      col += PVector.angleBetween(lightDiff, normals[dy+x]) * muu * b2;
      
      col = max(0, min(int(col), 255));
      col = (0xff << 24) + (col << 16) + (col << 8) + (col << 0);
      drawPixel(x,y,col,pixelSize);
    }
  }
  
  updatePixels();
  
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
