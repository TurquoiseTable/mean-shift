//Author: Diya Joy
//Project: Extended Essay - 3D
import java.util.*;

PImage a;
public static final float MAX_VALUE = 255f; //maximum intensity
public static final int KERNEL = 60; //kernel threshold
public static final int CSIZE = 5; //radius of neuron
public static final int DIM = 100;//dimensions of generated data set, > 10
public static final int CPOS = DIM/2; //initial position of neuron
public static final int MSIZE = 3*CSIZE; //radius of mean-shift sphere

public static final int MOVEBY = DIM / 40; //maximum amount neuron moves per frame
public static final int XSTART = (int)(CPOS - 1.5*CSIZE); //initial  x position of mean-shift
public static final int YSTART = (int)(CPOS - 1.5*CSIZE); //initial  y position of mean-shift
public static final int ZSTART = (int)(CPOS - 1.5*CSIZE); //initial  z position of mean-shift

public static final int MINVECTOR = 2; //threshold to stop mean-shift

Random rand = new Random();

//converts an image into a grayscale int[][][]
class ImageReader {
  String name;
  public static final int xDim = 95;
  public static final int yDim = 66;
  public static final int zDim = 34;

  public ImageReader(String filename) {
    name = filename;
  }

  //converts an image into a 2D data set with pixel values
  public int[][][] read(int t, int z) {
    int[][][] result = new int[xDim][yDim][zDim];
    String filename = name + "_t" + converter(t, 3) + "_z" + converter(z, 3) + ".png";
    PImage slice = loadImage(filename);
    slice.loadPixels();
    int count = 0;
    for (int i = 0; i < xDim; i++) {
      for (int j = 0; j < yDim; j++) {
        for (int k = 0; k < zDim; k++) {
          result[i][j][k] = (int)brightness(slice.pixels[count]);
          if (result[i][j][k] > 50) {
          }
        }
        count++;
      }
    }
    return result;
  }
}

class Point {
  int x;
  int y;
  int z;
  public Point(int xPos, int yPos, int zPos) {
    x = xPos;
    y = yPos;
    z = zPos;
  }
  public String toString() {
    return x + " " + y + " " + z;
  }
}

//simulates the neuron's random movements in 1D
public int jump(int x) {
  if (x < 0 + CSIZE) {
    x = 3 * CSIZE + (int)Math.abs(rand.nextGaussian());
  } else if (x > DIM - 3 * CSIZE) {
    x = (int)(DIM - 3 * CSIZE - rand.nextGaussian());
  } else {
    x += (int)(MOVEBY * rand.nextGaussian());
  }
  return x;
}

//simulates the neuron's random movements in 3D
public void movePoint(Point p) {
  p.x = jump(p.x);
  p.y = jump(p.y);
  p.z = jump(p.z);
}


//converts the file number to a format present in its name:
//e.x. 2 -> 002, 10 -> 010
public String converter(int x, int len) {
  int xLen = ("" + x).length();
  String result = "";
  for (int i = 0; i < len - xLen; i++) {
    result += "0";
  }
  result += x;
  return result;
}

//returns the mean of a given data set
public double mean(int[][][] a) {
  double result = 0;
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      for (int k = 0; k < a[0][0].length; k++) {
        result += a[i][j][k];
      }
    }
  }
  result /= a.length * a[0].length * a[0][0].length;
  return result;
}

//returns the standard deviation of a given data set
public double sd(int[][][] a) {
  double sd = 0;
  double mean = mean(a);
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      for (int k = 0; k < a[0][0].length; k++) {
        sd += pow((float)mean - a[i][j][k], 2.);
      }
    }
  }
  sd /= a.length * a[0].length * a[0][0].length;
  sd = pow((float)sd, 0.5f);

  return sd;
}

public double distanceTo(int x, int y, int z, int i, int j, int k) {
  return Math.sqrt(Math.pow(x-i, 2) + Math.pow(y-j, 2) + Math.pow(z-k, 2));
}

//generates a 3D data set of Gaussian noise with reference to an image
//generates and displays the background noise as well as the neuron in 3D grayscale
public float[][][] generateBackground(int x, int y, int z, int r) {
  final float multiple = 1.5; //multiplies the mean within the neuron

  float[][][] a = new float[DIM][DIM][DIM];
  for (int i = 0; i < DIM; i++) {
    for (int j = 0; j < DIM; j++) {
      for (int k = 0; k <DIM; k++) {
        float f = (float)(rand.nextGaussian() * SD + MEAN);

        if (distanceTo(x, y, z, i, j, k) <= r) {
          f = ((float)(rand.nextGaussian() * SD + multiple * MEAN));
        }
        set(i, j, color(f));
        a[i][j][k] = f;
      }
    }
  }
  return a;
}

//converts into a kernel-based boolean data set
public boolean[][][] createSet(float[][][] a) {
  boolean[][][] b = new boolean[a.length][a[0].length][a[0][0].length];
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      for (int k = 0; k < a[0][0].length; k++) {
        if (a[i][j][k] >= KERNEL) {
          b[i][j][k] = true;
          set(i, j, color(255));
        } else {
          b[i][j][k] = false;
          set(i, j, color(0));
        }
      }
    }
  }
  return b;
}

//mean-shift algorithm
public Point meanShift(boolean[][][] b, int x, int y, int z, int r) {
  Point p = centroid(b, x, y, z, r);
  if (distanceTo(p.x, p.y, p.z, x, y, z) < MINVECTOR) {
    return p;
  }
  return meanShift(b, p.x, p.y, p.z, r);
}

//returns the centroid of a 3D data set with a finite number of points
public Point centroid(boolean[][][] b, int x, int y, int z, int r) {
  int sumX = 0;
  int sumY = 0;
  int sumZ = 0;
  int count = 0;
  for (int i = 0; i < b.length; i++) {
    for (int j = 0; j < b[0].length; j++) {
      for (int k = 0; k < b[0][0].length; k++) {
        if (distanceTo(x, y, z, i, j, k) <= r) {
          if (b[i][j][k]) {
            sumX += i;
            sumY += j;
            sumZ += k;
            count ++;
          }
        }
      }
    }
  }
  sumX /= count;
  sumY /= count;
  sumZ /= count;
  Point p = new Point(sumX, sumY, sumZ);
  return p;
}

double MEAN = 0;
double SD = 0;

int count = 0;
double sum = 0;

Point cC = new Point(CPOS, CPOS, CPOS);
int move = MOVEBY;
int xPos = XSTART;
int yPos = YSTART;
int zPos = ZSTART;

//initialization code
void setup() {
  size(500, 500);
  colorMode(HSB, MAX_VALUE);

  ImageReader ir = new ImageReader("out");

  MEAN = mean(ir.read(1, 1));
  SD = 4 * sd(ir.read(10, 10));
}

//Processing calls draw() once per frame
//Each frame, the neuron is moved
//Mean-shift is called recursively until an estimation is reached
//The distance between the estimated and actual point is found
void draw() {
  count++;

  boolean[][][] a = createSet(generateBackground(cC.x, cC.y, cC.z, CSIZE));

  Point p = meanShift(a, xPos, yPos, zPos, MSIZE); 
  xPos = p.x;
  yPos = p.y;
  zPos = p.z;

  //averages the distance over 1000 trials
  sum += distanceTo(cC.x, cC.y, cC.z, xPos, yPos, zPos);
  if (count > 10) {
    println(sum / count);
    count = 0;
  }
  movePoint(cC);
}