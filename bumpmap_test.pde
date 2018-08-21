final boolean VISUALIZE_MAPS = false;
final int FPS = 60;
final int BUMP_MAP_DEPTH = 255;
final int BUMP_MAP_SOFTNESS = 10;
final int BUMP_MAP_RADIUS = 2;
final float COLOR_DIVIDER = 1 / 256.0;
final float INVERSE_PI = 1 / PI;

final int LIGHT_Z = 200;
final float LIGHT_FALLOFF_RADIUS = 180;
final float LIGHT_FALLOFF_SQ = LIGHT_FALLOFF_RADIUS*LIGHT_FALLOFF_RADIUS;
final color light1Col = color(255,64,64);
final color light2Col = color(64,64, 255);
final color light3Col = color(64,255,64);
final float lightBrightness = 1.0;

int bumpmapWidth, bumpmapHeight;
int halfWidth, halfHeight;
int[] heightMap;
PVector[] normalMap;
float[] light1, light2, light3;
float[] tmp1, tmp2, tmp3;
float mls;

float pixelRatioW = 1,
      pixelRatioH = 1;

void setup(){
  frameRate(FPS);
  size(640,360,P3D);
  //size(1280,720,P3D);
  
  // load the image to serve as a height map
  PImage img = loadImage("what_have_i_done.png");
  
  pixelRatioW = width / (float)img.width;
  pixelRatioH = height / (float)img.height;
  bumpmapWidth = img.width;
  bumpmapHeight = img.height;
  halfWidth = bumpmapWidth / 2;
  halfHeight = bumpmapHeight / 2;
  
  heightMap = createHeightMap(img);
  normalMap = createNormalMap(heightMap, bumpmapWidth);
  
  if(!VISUALIZE_MAPS){
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
}

int[] createHeightMap(PImage img){
  // get access to individual pixels of the height map
  img.loadPixels();
  
  int[] hmap = new int[img.pixels.length];
  
  // Transform the RGB image into a height map
  for(int y = 0; y < img.height; y++){
    int dy = y * img.width;
    for(int x = 0; x < img.width; x++){
      // Take an average of the RGB value
      // and scale it to BUMP_MAP_DEPTH
      hmap[dy+x] = int(((
        (img.pixels[dy+x] >> 16 & 0xff) + // red
        (img.pixels[dy+x] >> 8 & 0xff) +  // green
        (img.pixels[dy+x] & 0xff)         // blue
      ) / 3.0 * COLOR_DIVIDER - 0.5) * BUMP_MAP_DEPTH);
    }
  }
  
  return hmap;
}

PVector[] createNormalMap(int[] hmap, int w){
  PVector[] nmap = new PVector[hmap.length];
  
  for(int i = 0; i < hmap.length; ++i){
    // Calculate the positions of the neighbouring pixels
    int right = i + BUMP_MAP_RADIUS,
        down = i + w * BUMP_MAP_RADIUS;
        
    PVector vx = new PVector(),
            vy = new PVector();
    
    // Calculate a vector that points from the current pixel
    // position and height towards the pixel to the right
    vx.set(
      BUMP_MAP_SOFTNESS, 0, 
      hmap[right < hmap.length ? right : i] - hmap[i]
    );
    // Calculate a vector that points from the current pixel
    // position and height towards the pixel below
    vy.set(
      0, BUMP_MAP_SOFTNESS, 
      hmap[down < hmap.length ? down : i] - hmap[i]
    );
    
    // Calculate the perpendicular vector of vx and vy
    // that is the normal vector for the current pixel
    // on the height map
    nmap[i] = vx.cross(vy).normalize();
  };
  
  return nmap;
}

float rot = 0;
void draw(){
  if(VISUALIZE_MAPS){
    clear();
    translate(width / 2, height / 2 - height * 0.01, height * 0.7);
    rotateX(2.5 * INVERSE_PI);
    rotateZ(rot);
    rot += 0.01;
    
    int jump = 3;
    
    for(int y = 0; y < bumpmapHeight; y += jump){
      int dy = y * bumpmapWidth;
      for(int x = 0; x < bumpmapWidth; x += jump){
        pushMatrix();
        
        float z = heightMap[dy+x] * 0.1;
        
        translate(
          x - halfWidth,
          y - halfHeight,
          0
        );
        int col = int(heightMap[dy+x] + BUMP_MAP_DEPTH * 0.5);
        float z1 = z, z2 = z, z3 = z;
        noStroke();
        fill(col);
        beginShape(QUADS);
        vertex(0,0,z);
        if(dy + x + jump < heightMap.length){
          z1 = heightMap[dy+x+jump] * 0.1;
          vertex(jump, 0, z1);
        }
        if(dy + x + jump + bumpmapWidth * jump < heightMap.length){
          z2 = heightMap[dy+x+jump+bumpmapWidth*jump] * 0.1;
          vertex(jump, jump, z2);
        }
        if(dy + x + bumpmapWidth * jump < heightMap.length){
          z3 = heightMap[dy+x+bumpmapWidth*jump] * 0.1;
          vertex(0, jump, z3);
        }
        endShape();
        
        translate(jump * 0.5, jump * 0.5, (z + z1 + z2 + z3) * 0.25);
  
        stroke(0, 255, 0);
        strokeWeight(2);
        PVector normal = new PVector();
        normal.set(normalMap[dy+x]);
        normal.mult(3);
        line(0, 0, 0, normal.x, normal.y, normal.z);
        
        popMatrix();
      }
    }
  }
  else 
  {
  
    mls = millis();
    float dy = 0;
    float dx = 0;
    
    for(int y = 0; y < height; y++){
      dy = y / (float)height;
      for(int x = 0; x < width; x++){
        dx = x / (float)width;
        int r = 0;
        int g = 0;
        int b = 0;
        int col = 0xffffffff;
        float brightness = 0;
        
        brightness = getBrightness(dx,dy,light1);
        r += (light1Col >> 16 & 0xff) * brightness;
        g += (light1Col >> 8 & 0xff) * brightness;
        b += (light1Col & 0xff) * brightness;
        
        brightness = getBrightness(dx,dy,light2);
        r += (light2Col >> 16 & 0xff) * brightness;
        g += (light2Col >> 8 & 0xff) * brightness;
        b += (light2Col & 0xff) * brightness;
        
        brightness = getBrightness(dx,dy,light3);
        r += (light3Col >> 16 & 0xff) * brightness;
        g += (light3Col >> 8 & 0xff) * brightness;
        b += (light3Col & 0xff) * brightness;
        
        r = min(255, int((col >> 16 & 0xff) * r * COLOR_DIVIDER ));
        g = min(255, int((col >> 8 & 0xff) * g * COLOR_DIVIDER ));
        b = min(255, int((col & 0xff) * b * COLOR_DIVIDER ));
        
        int c = b + (g << 8) + (r << 16) + (0xff000000);
        
        drawPixel(x, y, c);
      }
    }
    
    updatePixels();
    
    text(frameRate, 20, 20);
  }
}

void drawPixel(int x, int y, int col){
  pixels[(y)*width+x] = col;
}

boolean onCanvas(int i){
  return i > 0 && i < pixels.length;
}

float getBrightness(float x, float y, float[] lightMap){
  float b1,b2,b3,b4;
  float dx = bumpmapWidth * x;
  float dy = bumpmapHeight * y;
  float nx = dx - (int)dx;
  float ny = dy - (int)dy;
  int addr = (int)dy * bumpmapWidth + (int)dx;
  b1 = lightMap[addr] * (1-nx)*(1-ny);
  
  addr = (int)dy * bumpmapWidth + (int)(dx+1);
  if(addr < lightMap.length){
    b2 = lightMap[addr] * nx*(1-ny);
  }
  else {
    b2  = b1;
  }
  
  addr = (int)(dy+1) * bumpmapWidth + (int)dx;
  if(addr < lightMap.length){
    b3 = lightMap[addr] * (1-nx)*ny;
  }
  else {
    b3  = b1;
  }
  
  addr = (int)(dy+1) * bumpmapWidth + (int)(dx+1);
  if(addr < lightMap.length){
    b4 = lightMap[addr] * nx*ny;
  }
  else {
    b4  = b1;
  }
  
  return b1+b2+b3+b4;
}

void updateLightmap1(){
  while(true){
    int start = millis();
    PVector l = new PVector( (cos(start*0.001)) * halfWidth + halfWidth, 
                             (sin(start*0.0009)) * halfHeight + halfHeight, 
                             sin(start*0.0008) * 40 + LIGHT_Z);
    updateLightmap(l, tmp1);
    flushLightmap(tmp1, light1);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
}
void updateLightmap2(){
  while(true){
    int start = millis();
    PVector l = new PVector( 
                            (cos((start)*0.0012))*halfWidth + halfWidth, 
                            (sin((start)*0.00093))*halfHeight + halfHeight, 
                            sin((start+2342)*0.0007) * 40 + LIGHT_Z);
    updateLightmap(l, tmp2);
    flushLightmap(tmp2, light2);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
}
void updateLightmap3(){
  while(true){
    int start = millis();
    PVector l = new PVector( 
                            (cos((start)*0.0013))*halfWidth + halfWidth, 
                            (sin((start)*0.00091))*halfHeight + halfHeight, 
                            sin((start+5324)*0.0006) * 40 + LIGHT_Z);
    updateLightmap(l, tmp3);
    flushLightmap(tmp3, light3);
    delay(max(0, 1000/FPS - (millis()-start)));
  }
}

PVector up = new PVector(0,0,-1);
void updateLightmap(PVector light_pos, float[] light_map){
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
      // Get the direction of the light source
      lightDir.set(
                    thispixel.x - light_pos.x, 
                    thispixel.y - light_pos.y, 
                    thispixel.z - light_pos.z
                  );
      // Calculate the brightness of the light based on it's distance
      brightness = LIGHT_FALLOFF_SQ / lightDir.magSq();
      brightness *= lightBrightness;
      
      normal.set(normalMap[dy+x]);
      cross.set(
                 lightDir.y * normal.z - lightDir.z * normal.y,
                 lightDir.z * normal.x - lightDir.x * normal.z,
                 lightDir.x * normal.y - lightDir.y * normal.x
               );
      light_map[dy+x] = atan2(cross.mag(), normal.dot(lightDir)) *
                        INVERSE_PI * brightness;
                        
      //cross.set(lightDir.add(normal.mult(lightDir.dot(normal) * -2)));                  
      //light_map[dy+x] = PVector.angleBetween(up,cross) *
      //                  INVERSE_PI * brightness;
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
