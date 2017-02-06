//Author: Diya Joy
//Project: Extended Essay - 2D
import java.util.*;

PImage a;

public static final float MAX_VALUE = 255f; //maximum intensity
public static final int KERNEL = 60; //kernel threshold
public static final int CSIZE = 50; //radius of neuron
public static final int DIM = 1000; //dimensions of generated data set
public static final int CPOS = DIM/2; //initial position of neuron
public static final int MSIZE = 3*CSIZE; //radius of mean-shift circle

public static final int MOVEBY = 25; //maximum amount neuron moves per frame
public static final int XSTART = (int)(CPOS - 1.5*CSIZE); //initial x position of mean-shift
public static final int YSTART = (int)(CPOS - 1.5*CSIZE); //initial y position of mean-shift

public static final int MINVECTOR = 2; //threshold to stop mean-shift

Random rand = new Random();

//converts an image into a grayscale int[][]
class ImageReader {
  String name;
  public static final int xDim = 95;
  public static final int yDim = 66;

  public ImageReader(String filename) {
    name = filename;
  }

  //converts an image into a 2D data set with pixel values
  public int[][] read(int t, int z) {
    int[][] result = new int[xDim][yDim];
    String filename = name + "_t" + converter(t, 3) + "_z" + converter(z, 3) + ".png";
    PImage slice = loadImage(filename);
    slice.loadPixels();
    int count = 0;
    for (int i = 0; i < xDim; i++) {
      for (int j = 0; j < yDim; j++) {
        result[i][j] = (int)brightness(slice.pixels[count]);
        if (result[i][j] > 50) {
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
  public Point(int xPos, int yPos) {
    x = xPos;
    y = yPos;
  }
  public String toString() {
    return x + " " + y;
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

//simulates the neuron's random movements in 2D
public void movePoint(Point p) {
  p.x = jump(p.x);
  p.y = jump(p.y);
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
public double mean(int[][] a) {
  double result = 0;
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      result += a[i][j];
    }
  }
  result /= a.length * a[0].length;
  return result;
}

//returns the standard deviation of a given data set
public double sd(int[][] a) {
  double sd = 0;
  double mean = mean(a);
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      sd += pow((float)mean - a[i][j], 2.);
    }
  }
  sd /= a.length * a[0].length;
  sd = pow((float)sd, 0.5f);

  return sd;
}

public double distanceTo(int x, int y, int i, int j) {
  return Math.sqrt(Math.pow(x-i, 2) + Math.pow(y-j, 2));
}

//generates a 2D data set of Gaussian noise with reference to an image
//generates and displays the background noise as well as the neuron in 2D grayscale
public float[][] generateBackground(int x, int y, int r) {
  final float multiple = 3f;//multiplies the mean within the neuron

  float[][] a = new float[DIM][DIM];
  for (int i = 0; i < DIM; i++) {
    for (int j = 0; j < DIM; j++) {
      float f = (float)(rand.nextGaussian() * SD + MEAN);

      if (distanceTo(x, y, i, j) <= r) {
        f = (float)(rand.nextGaussian() * SD + multiple * MEAN);
      }
      set(i, j, color(f));
      a[i][j] = f;
    }
  }
  return a;
}

//converts into a kernel-based boolean data set
public boolean[][] createSet(float[][] a) {
  boolean[][] b = new boolean[a.length][a[0].length];
  for (int i = 0; i < a.length; i++) {
    for (int j = 0; j < a[0].length; j++) {
      if (a[i][j] >= KERNEL) {
        b[i][j] = true;
        //set(i, j, color(255));
      } else {
        b[i][j] = false;
        //set(i, j, color(0));
      }
    }
  }
  return b;
}

//mean-shift algorithm
public Point meanShift(boolean[][] b, int x, int y, int r) {
  Point p = centroid(b, x, y, r);
  if (distanceTo(p.x, p.y, x, y) < MINVECTOR) {
    return p;
  }
  return meanShift(b, p.x, p.y, r);
}

//returns the centroid of a 2D data set with a finite number of points
public Point centroid(boolean[][] b, int x, int y, int r) {
  int sumX = 0;
  int sumY = 0;
  int count = 0;
  for (int i = 0; i < b.length; i++) {
    for (int j = 0; j <b[0].length; j++) {
      if (distanceTo(x, y, i, j) <= r) {
        if (b[i][j]) {
          sumX += i;
          sumY += j;
          count ++;
        }
      }
    }
  }
  sumX /= count;
  sumY /= count;
  Point p = new Point(sumX, sumY);
  return p;
}

double MEAN;
double SD;

int count = 0;
double sum = 0;

Point cC = new Point(CPOS, CPOS);
int move = MOVEBY;
int xPos = XSTART;
int yPos = YSTART;

//initialization code
void setup() {
  size(1000, 1000);
  colorMode(HSB, MAX_VALUE);

  ImageReader ir = new ImageReader("out");

  MEAN = mean(ir.read(1, 1));
  SD = 5 * sd(ir.read(10, 10));
}

//Processing calls draw() once per frame
//Each frame, the neuron is moved
//Mean-shift is called recursively until an estimation is reached
//The distance between the estimated and actual point is found
void draw() {
  count++;

  boolean[][] a = createSet(generateBackground(cC.x, cC.y, CSIZE));

  Point p = meanShift(a, xPos, yPos, MSIZE);
  xPos = p.x;
  yPos = p.y;
  //ellipse(xPos, yPos, 20, 20);

  //averages the distance over 1000 trials
  sum+=distanceTo(cC.x, cC.y, xPos, yPos);
  if (count >= 1000) {
    println(sum / count);
    count = 0;
  }
  movePoint(cC);
}