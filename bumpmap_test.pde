final int FPS = 60;
final int BUMP_MAP_DEPTH = 200;
final int BUMP_MAP_SOFTNESS = 2;
final int BUMP_MAP_RADIUS = 1;

int bumpmapWidth, bumpmapHeight;
int halfWidth, halfHeight;
float[] heightMap;
PVector[] normalMap;
float[] light1, light2, light3;
float[] tmp1, tmp2, tmp3;
PImage img;

float mInversePI = 1 / PI;
float brightness = 0.7;
float falloff = 200;
float falloffSq = falloff*falloff;
color light1Col = color(255,64,64);
color light2Col = color(64,64, 255);
color light3Col = color(64,255,64);
float lightBrightness = 0.5;
float colorDivider = 1/256.0;
float mls;

float pixelRatioW = 1,
      pixelRatioH = 1;

void setup(){
  frameRate(FPS);
  size(640,360);
  //fullScreen();
  
  prepareNormalMap("what_have_i_done.png");
  
  light1 = new float[heightMap.length];
  light2 = new float[heightMap.length];
  light3 = new float[heightMap.length];
  tmp1 = new float[heightMap.length];
  tmp2 = new float[heightMap.length];
  tmp3 = new float[heightMap.length];
  
  thread("updateLightmap1");
  thread("updateLightmap2");
  thread("updateLightmap3");
  
  // get pixel level access to the main canvas
  loadPixels();
}

void prepareNormalMap(String img_path){
  // load the image to serve as a height map
  PImage img = loadImage(img_path);
  // get access to individual pixels of the height map
  img.loadPixels();
  
  pixelRatioW = width/(float)img.width;
  pixelRatioH = height/(float)img.height;
  bumpmapWidth = img.width;
  bumpmapHeight = img.height;
  halfWidth = bumpmapWidth/2;
  halfHeight = bumpmapHeight/2;
  
  heightMap = new float[img.pixels.length];
  normalMap = new PVector[img.pixels.length];
  
  // Transform the RGB image into a height map
  for(int y=0; y<img.height; y++){
    int dy = y*img.width;
    for(int x=0; x<img.width; x++){
      // Take an average of the RGB value
      // and scale it to BUMP_MAP_DEPTH
      heightMap[dy+x] = (
        (img.pixels[dy+x] & 0xff) + 
        (img.pixels[dy+x] >> 8 & 0xff) +
        (img.pixels[dy+x] >> 16 & 0xff) 
      ) / 3 * colorDivider * BUMP_MAP_DEPTH - BUMP_MAP_DEPTH / 2;
    }
  }
  
  for(int i=0; i<heightMap.length; ++i){
    // Calculate the positions of the neighbouring pixels
    int right = i+BUMP_MAP_RADIUS,
        down = i+img.width*BUMP_MAP_RADIUS;
        
    PVector vx = new PVector(),
            vy = new PVector();
    
    // Calculate a vector that points from the current pixel
    // position and height towards the pixel to the right
    vx.set(
      BUMP_MAP_SOFTNESS, 0, 
      heightMap[right<heightMap.length ? right : i] - heightMap[i]
    );
    // Calculate a vector that points from the current pixel
    // position and height towards the pixel below
    vy.set(
      0, BUMP_MAP_SOFTNESS, 
      heightMap[down<heightMap.length ? down : i] - heightMap[i]
    );
    
    // Calculate the perpendicular vector of vx and vy
    // that is the normal vector for the current pixel
    // on the height map
    normalMap[i] = vx.cross(vy).normalize();
  };
}

void draw(){
  mls = millis();
  int dy = 0;
  
  for(int y=0; y<bumpmapHeight; y++){
    dy = y*bumpmapWidth;
    for(int x=0; x<bumpmapWidth; x++){
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
      
      drawPixel(x,y,c);
    }
  }
  
  updatePixels();
  
  text(frameRate, 20, 20);
}

void drawPixel(int x, int y, int col){
  x *= pixelRatioW;
  y *= pixelRatioH;
  for(int dy=0; dy<pixelRatioH; ++dy){
    for(int dx=0; dx<pixelRatioW; ++dx){
      pixels[(y+dy)*width+x+dx] = col;
    }
  }
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
  PVector thispixel = new PVector(),
          normal = new PVector(),
          lightDir = new PVector(),
          cross = new PVector();
  float brightness = 0;
    
  for(int y=0; y<bumpmapHeight; y++){
    dy = y*bumpmapWidth;
    for(int x=0; x<bumpmapWidth; x++){
      thispixel.set(x, y, heightMap[dy+x]);
      lightDir.set(thispixel.x - lpos.x, thispixel.y - lpos.y, thispixel.z - lpos.z);
      brightness = falloffSq/lightDir.magSq();
      brightness *= lightBrightness;
      normal.set(normalMap[dy+x]);
      cross.set(
                 lightDir.y * normal.z - lightDir.z * normal.y,
                 lightDir.z * normal.x - lightDir.x * normal.z,
                 lightDir.x * normal.y - lightDir.y * normal.x
               );
      
      lmap[dy+x] = atan2(cross.mag(), normal.dot(lightDir)) * mInversePI * brightness;
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
