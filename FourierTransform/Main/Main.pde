import java.util.Arrays;

float time, dx, spacing = 20; // increase accel if you want. if you decrease it you'll get bad results. Spacing is the minimum distance between two drawn points
int maxH = 1; // maximum number of harmonics to generate the fourier series.

float hWid, hHei; // constants for width/2 and height/2

boolean start = false;
ArrayList<PVector> input;
fCoef[] path;

class fCoef { // class to store frequency of the coefficients. storing the values in class instead of calculating in our loop is more efficient
  float x, y, am, ph;
  int fr;

  fCoef(PVector c, int freq) {
    x = c.x;
    y = c.y;
    fr = freq;
  }

  void add(PVector c) { x += c.x; y += c.y; } // Vector addition for the complex plane.

  void div(int k) { x /= k; y /= k; } // Scalar division for real inputs.

  void upd(int freq) { am = sqrt(x*x + y*y); ph = atan2(y, x); fr = freq; } // Updates the amplitude, phase, and frequency.

  public String toString() {
    return String.format("fr: %d | (%.3f + %.3fi) | am: %.3f | ph: %.3f", fr, x, y, am, ph);
  }
}

fCoef[] DFT(ArrayList<PVector> x) { // https://en.wikipedia.org/wiki/Discrete_Fourier_transform
  int N = x.size();
  fCoef[] f = new fCoef[N];

  for (int k = 0; k < N; k++) {
    fCoef next = new fCoef(new PVector(0, 0), 0);

    for (int j = 0; j < N; j++) { //                                                                              |
      float theta = (TAU*k*j)/N; //                                                                               |
      PVector a = x.get(j), b = new PVector(cos(theta), -sin(theta)); //                                          |                           |  a  |     b      |
                                                                      //                                          |  X_n = 1/N * sum_[N-1:n=0]( x_n * e^-2PIkn/N )                             
      next.add(new PVector(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x)); // complex number multiplication (x: re, y: im)|
    } //                                                                                                          |
    next.div(N); //                                                                                               |
    
    next.upd(k); // update the frequency, amplitude, and phase of our next value.
    f[k] = next;
  }
  return f;
}

void fourier() { // rendering the fourier series
  if (start) {
    int N = path.length;
    float x = 0, y = 0;
    for (int i = 0; i < N && i < maxH; i++) {
      fCoef c = path[i];
      float dx = x, dy = y, amp = c.am, pha = c.ph, fr = c.fr;

      x += amp*cos(pha+fr*time);
      y += amp*sin(pha+fr*time);

      strokeWeight(1);
      circle(dx, dy, amp*2);

      strokeWeight(4);
      point(dx, dy);
    }
    strokeWeight(3);
    beginShape();
    for (float t = 0; t < TAU; t += dx) { // Rendering it's path
      float x2 = 0, y2 = 0;
      for (int i = 0; i < N && i < maxH; i++) {
        fCoef c = path[i];
        float amp = c.am, pha = c.ph, fr = c.fr;

        x2 += amp*cos(pha+fr*t);
        y2 += amp*sin(pha+fr*t);
      }
      vertex(x2, y2);
    }
    endShape();

    push();
    stroke(255);
    strokeWeight(5);
    point(x, y);
    pop();

    if (time > TAU) {
      if (maxH < N) maxH++;
      time = 0;
    }

    time += dx;
  } else {
    push(); // Cosmetic stuff
    strokeWeight(3);
    stroke(90);
    for (float x = -hWid; x < hWid; x+=width/60) line(x, -hHei, x, hHei);
    for (float y = -hHei; y < hHei; y+=height/60) line(-hWid, y, hWid, y);

    stroke(255);
    strokeWeight(5);
    point(0, 0);

    stroke(127);
    strokeWeight(10); // rendering input points
    for (PVector p : input) point(p.x, p.y);
    pop();
  }
  push();
  fill(0);
  text(maxH + " Harmonics", 0, -hHei+20);
  text(String.format("Path length: %d\nTime: %.3f\ndx: 2π/%d\nDrawing mode: %b", input.size(), time, input.size()*2, !start), -hWid+10, -hWid+20);
  pop();
}

void mousePressed() {
  if (mouseButton == CENTER) {
    path = DFT(input);
    sortA(path, 0, path.length-1);

    time = 0;

    if(key == SHIFT) input.add(new PVector(mouseX-hWid, mouseY-hHei));

    dx = TAU/path.length;
    start = !start;
  }
  if (mouseButton == RIGHT && !start) input.clear();
}
void mouseWheel(MouseEvent e) {
  if(maxH > input.size()) maxH = input.size()-1;
  
  if (e.getCount() < 0 && maxH < input.size()) maxH++;
  else if (e.getCount() > 0 && maxH > 1) maxH--;
}
void mouseDragged() {
  if (!start) {
    PVector c = new PVector(mouseX-hWid, mouseY-hHei), prev;

    if(mouseButton == LEFT) // handles input painting
      if (input.size() > 0) {
        prev = input.get(input.size()-1);
        if (dist(prev.x, prev.y, c.x, c.y) > spacing) {
          input.add(c);
        }
      } else input.add(c); 
  }
}
void setup() {
  size(900, 900);
  hWid = width/2;
  hHei = height/2;

  noFill();

  input = new ArrayList<>();
  path = new fCoef[0];

  float w = width/4, h = height/4; // starting box
  for (float x = -w; x < w; x+=10) input.add(new PVector(x, h));
  for (float y = h; y > -h; y-=10) input.add(new PVector(w, y));
  for (float x = w; x > -w; x-=10) input.add(new PVector(x, -h));
  for (float y = -h; y < h; y+=10) input.add(new PVector(-w, y));
}
void draw() {
  background(70);
  translate(hWid, hHei);

  fourier();
}

void sortA(fCoef[] arr, int low, int high) {
  if (low < high) {
    int ind = partition(arr, low, high);

    sortA(arr, low, ind-1);
    sortA(arr, ind+1, high);
  }
}
int partition(fCoef[] arr, int low, int high) { // quicksort
  fCoef p = arr[high];

  int i = low-1;

  for (int j = low; j < high; j++)
    if (arr[j].am > p.am) {
      i++;
      swap(arr, i, j);
    }
  swap(arr, i+1, high);
  return i+1;
}
void swap(fCoef[] arr, int a, int b) {
  fCoef tmp = arr[a];
  arr[a] = arr[b];
  arr[b] = tmp;
}
