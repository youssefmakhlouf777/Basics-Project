// ============================================================

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import java.io.OutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.util.UUID;
import java.util.ArrayList;

// ============================================================
//  BLUETOOTH MAC ADDRESS
// ============================================================
String MAC_ADDRESS = "00:24:08:00:59:B6";   // ← UPDATE THIS

// ---------- Bluetooth ----------
BluetoothAdapter btAdapter;
BluetoothSocket  btSocket;
OutputStream     btOutput;
InputStream      btInput;
boolean          btConnected  = false;
String           btStatus     = "Disconnected";
String           btIncoming   = "";

UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB");

// ---------- App State ----------
int screen = 0;        // 0=Sorting, 1=Result, 2=Shooting
int prevScreen = 0;

String sortChoice = "";     // "fish" or "garbage"
String actualColor = "";    // "green" or "red"
boolean resultShown = false;
boolean correct = false;

// Shooting
int launchSpeed = 75;
int score = 0;
int totalRounds = 0;

// Ball tracking
String ballLocation = "Waiting for signal...";
float ballLocAlpha = 255;
float ballLocSlide = 0;

// ---------- Dimensions ----------
float dp, sp;
float W, H, PAD, TAB_H, BTN_H, CARD_R, STATUS_H;

// ---------- Professional Color Palette ----------
color C_BG        = color(5, 8, 18);      // Deep space navy
color C_BG2       = color(12, 15, 28);
color C_SURFACE   = color(18, 22, 38);
color C_GLASS     = color(255, 255, 255, 12);
color C_GLASS2    = color(255, 255, 255, 6);
color C_BORDER    = color(90, 110, 160, 55);
color C_PRIMARY   = color(70, 160, 255);
color C_CYAN      = color(0, 220, 255);
color C_SUCCESS   = color(40, 230, 160);
color C_DANGER    = color(255, 65, 85);
color C_FISH      = color(255, 70, 90);   // Fish red
color C_GARBAGE   = color(40, 230, 160);   // Garbage green
color C_TEXT      = color(235, 240, 255);
color C_MUTED     = color(130, 145, 180);
color C_WHITE     = color(255);
color C_GOLD      = color(255, 215, 80);

// ---------- Animations ----------
float connectAnim = 1.0;
float fishAnim = 1.0;
float garbAnim = 1.0;
float shootBtnAnim = 1.0;
float resultAlpha = 0;
float resultScale = 0.6;
float shakeX = 0;
float shakeDecay = 0;
float glowPulse = 0;
float energyPulse = 0;
float tabSlide = 0;

// New background timer replacing the old lines
float bgTime = 0; 

// Transition
float transAlpha = 0;
boolean transIn = false;
int transTarget = -1;

// Toast
String toastMsg = "";
int toastTimer = 0;

// Particles
ArrayList<Particle> particles = new ArrayList<Particle>();

// Connection pulse
float connDotPulse = 0;

// ============================================================
//  PARTICLE SYSTEM
// ============================================================
class Particle {
  float x, y, vx, vy, life, maxLife, sz;
  color col;
  Particle(float px, float py, color c) {
    x = px; y = py;
    float angle = random(TWO_PI);
    float speed = random(1.8, 7) * dp;
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;
    sz = random(3.5, 11) * dp;
    life = maxLife = random(35, 85);
    col = c;
  }
  void update() {
    x += vx; y += vy;
    vy += 0.12 * dp;
    life--;
    vx *= 0.965;
  }
  void draw() {
    float a = life / maxLife;
    fill(red(col), green(col), blue(col), 255 * a * a);
    noStroke();
    ellipse(x, y, sz * a, sz * a);
  }
  boolean dead() { return life <= 0; }
}

// ============================================================
//  SETUP
// ============================================================
void setup() {
  fullScreen();
  orientation(PORTRAIT);
  smooth(8);

  dp = displayDensity;
  sp = displayDensity;

  W = width;
  H = height;
  PAD = 20 * dp;
  TAB_H = 56 * dp;
  BTN_H = 58 * dp;
  CARD_R = 24 * dp;
  STATUS_H = 58 * dp;

  textFont(createFont("SansSerif", 15 * sp, true));

  btAdapter = BluetoothAdapter.getDefaultAdapter();
}

// ============================================================
//  DRAW
// ============================================================
void draw() {
  drawProfessionalBackground();

  bgTime += 0.005; // Drives the smooth, slow background motion
  glowPulse = (glowPulse + 0.035) % TWO_PI;
  energyPulse = (energyPulse + 0.048) % TWO_PI;
  connDotPulse = (connDotPulse + 0.055) % TWO_PI;

  updateParticles();

  drawStatusBar();
  drawTabBar();

  float contentY = STATUS_H + TAB_H;

  if (screen == 0) drawSortingScreen(contentY);
  else if (screen == 1) drawResultScreen(contentY);
  else if (screen == 2) drawShootingScreen(contentY);

  drawTransition();
  drawToast();

  decayAnimations();
  readBluetooth();
}

// ============================================================
//  PREMIUM INDUSTRIAL BACKGROUND (Marine / Automation Style)
// ============================================================
void drawProfessionalBackground() {
  background(C_BG);

  // 1. Base depth gradient (Deep marine/space navy)
  for (int i = 0; i < 3; i++) {
    float r = H * (0.8 - i * 0.25);
    float a = map(i, 0, 2, 10, 3);
    fill(20, 35, 70, a);
    ellipse(W * 0.5, H * 0.5, r * 1.4, r);
  }

  // 2. Slow-orbiting, volumetric ambient lights (Baby-blue & Cyan)
  // These simulate high-end LED indicator glows reflecting off dark surfaces
  float x1 = W * 0.5 + sin(bgTime * 0.7) * W * 0.3;
  float y1 = H * 0.35 + cos(bgTime * 0.5) * H * 0.2;
  fill(C_PRIMARY, 14);
  ellipse(x1, y1, W * 1.1, W * 1.1);
  fill(C_PRIMARY, 8);
  ellipse(x1, y1, W * 0.5, W * 0.5);

  float x2 = W * 0.5 + cos(bgTime * 0.6) * W * 0.35;
  float y2 = H * 0.65 + sin(bgTime * 0.8) * H * 0.2;
  fill(C_CYAN, 10);
  ellipse(x2, y2, W * 1.3, W * 1.3);
  fill(C_CYAN, 6);
  ellipse(x2, y2, W * 0.6, W * 0.6);

  // 3. Faint precision engineering grid (Subtle automation feel)
  stroke(255, 255, 255, 3); // Extremely low opacity
  strokeWeight(dp * 0.8);
  float gridSize = 45 * dp;
  
  // Grid pans imperceptibly slowly
  float offsetX = (bgTime * 8 * dp) % gridSize; 
  float offsetY = (bgTime * 12 * dp) % gridSize;
  
  for (float x = -gridSize + offsetX; x <= W; x += gridSize) {
    line(x, 0, x, H);
  }
  for (float y = -gridSize + offsetY; y <= H; y += gridSize) {
    line(0, y, W, y);
  }
  noStroke();

  // 4. Subtle top/bottom edge darkening (Vignette) 
  // Keeps the user's eyes focused on the center UI elements
  for(int i = 0; i < 5; i++) {
    fill(red(C_BG), green(C_BG), blue(C_BG), 40 - (i * 8));
    rect(0, i * 15 * dp, W, 15 * dp);                 // Top fade
    rect(0, H - ((i + 1) * 15 * dp), W, 15 * dp);     // Bottom fade
  }
}

// ============================================================
//  PARTICLES
// ============================================================
void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.draw();
    if (p.dead()) particles.remove(i);
  }
}

void spawnParticles(float x, float y, color col, int count) {
  for (int i = 0; i < count; i++) {
    particles.add(new Particle(x, y, col));
  }
}

// ============================================================
//  STATUS BAR
// ============================================================
void drawStatusBar() {
  fill(C_SURFACE, 235);
  noStroke();
  rect(0, 0, W, STATUS_H);
  stroke(C_BORDER);
  strokeWeight(0.8 * dp);
  line(0, STATUS_H, W, STATUS_H);
  noStroke();

  // BT indicator
  float dotR = (5 + sin(connDotPulse) * 1.8) * dp;
  color dotCol = btConnected ? C_SUCCESS : C_DANGER;
  fill(red(dotCol), green(dotCol), blue(dotCol), 45);
  ellipse(PAD + 8 * dp, STATUS_H / 2, dotR * 3.2, dotR * 3.2);
  fill(dotCol);
  ellipse(PAD + 8 * dp, STATUS_H / 2, dotR * 2, dotR * 2);

  fill(btConnected ? C_SUCCESS : C_MUTED);
  textSize(12 * sp);
  textAlign(LEFT, CENTER);
  text(btConnected ? "CONNECTED" : "DISCONNECTED", PAD + 22 * dp, STATUS_H * 0.37);

  // Ball location with slide animation
  if (ballLocSlide > 0) {
    ballLocSlide = lerp(ballLocSlide, 0, 0.16);
    ballLocAlpha = lerp(ballLocAlpha, 255, 0.14);
  }
  fill(C_CYAN, ballLocAlpha);
  textSize(11 * sp);
  textAlign(LEFT, CENTER);
  text(ballLocation, PAD + 22 * dp + ballLocSlide, STATUS_H * 0.72);

  // Connect button
  float bw = 108 * dp, bh = 32 * dp;
  float bx = W - PAD - bw;
  float by = STATUS_H / 2 - bh / 2;

  pushMatrix();
  float cs = connectAnim;
  translate(bx + bw / 2, STATUS_H / 2);
  scale(cs);
  translate(-(bx + bw / 2), -STATUS_H / 2);

  fill(btConnected ? color(40, 230, 160, 38) : color(100, 160, 255, 32));
  noStroke();
  rect(bx, by, bw, bh, bh / 2);
  stroke(btConnected ? C_SUCCESS : C_PRIMARY);
  strokeWeight(1.2 * dp);
  noFill();
  rect(bx, by, bw, bh, bh / 2);

  fill(btConnected ? C_SUCCESS : C_PRIMARY);
  textSize(12 * sp);
  textAlign(CENTER, CENTER);
  text(btConnected ? "DISCONNECT" : "CONNECT", bx + bw / 2, STATUS_H / 2);
  popMatrix();


}

// ============================================================
//  TAB BAR
// ============================================================
void drawTabBar() {
  float y = STATUS_H;
  float target = (screen == 2) ? 1.0 : 0.0;
  tabSlide = lerp(tabSlide, target, 0.16);

  fill(C_SURFACE, 210);
  rect(0, y, W, TAB_H);

  String[] labels = {"SORTING", "SHOOTING"};
  float tw = W / 2;
  for (int i = 0; i < 2; i++) {
    float x = i * tw;
    boolean active = (i == 0 && screen != 2) || (i == 1 && screen == 2);
    if (active) {
      fill(red(C_PRIMARY), green(C_PRIMARY), blue(C_PRIMARY), 28);
      rect(x, y, tw, TAB_H);
    }
    fill(active ? C_PRIMARY : C_MUTED);
    textSize(14 * sp);
    textAlign(CENTER, CENTER);
    text(labels[i], x + tw / 2, y + TAB_H / 2);
  }

  float indX = tabSlide * tw;
  fill(C_PRIMARY);
  rect(indX + PAD, y + TAB_H - 4 * dp, tw - PAD * 2, 4 * dp, 2 * dp);
}

// ============================================================
//  SORTING SCREEN
// ============================================================
void drawSortingScreen(float y) {
  y += PAD * 1.1;

  drawSectionHeader("CLASSIFY ITEM", "Select the detected object", y);
  y += 78 * dp;

  float cardW = (W - PAD * 3) / 2;
  float cardH = H * 0.285;

  drawChoiceCard("FISH", "Red Sensor", PAD, y, cardW, cardH,
                 sortChoice.equals("fish"), C_FISH, fishAnim);

  drawChoiceCard("GARBAGE", "Green Sensor", PAD * 2 + cardW, y, cardW, cardH,
                 sortChoice.equals("garbage"), C_GARBAGE, garbAnim);

  y += cardH + PAD * 1.4;

  if (!sortChoice.isEmpty()) {
    String txt = sortChoice.equals("fish") ? "ROUTE TO SEA" : "ROUTE TO SHOOTER";
    color c = sortChoice.equals("fish") ? C_FISH : C_GARBAGE;
    drawGlassInfoRow("Command", txt, c, y);
  } else {
    drawGlassInfoRow("Status", "Make your selection", C_MUTED, y);
  }
  y += 58 * dp;

  boolean canSend = !sortChoice.isEmpty() && btConnected;
  color btnCol = sortChoice.equals("fish") ? C_FISH : C_GARBAGE;
  String label = sortChoice.isEmpty() ? "SELECT OPTION" : "CONFIRM " + sortChoice.toUpperCase();

  drawPrimaryBtn(label, PAD, y, W - PAD * 2, BTN_H,
                 canSend ? btnCol : C_SURFACE,
                 canSend ? C_BG : C_MUTED,
                 connectAnim, canSend);  // reuse anim var
}

// ============================================================
//  RESULT SCREEN
// ============================================================
void drawResultScreen(float y) {
  resultAlpha = lerp(resultAlpha, 255, 0.11);
  resultScale = lerp(resultScale, 1.0, 0.13);

  if (shakeDecay > 0) {
    shakeX = sin(shakeDecay * 2.1) * shakeDecay * 0.8 * dp;
    shakeDecay = max(0, shakeDecay - 1.0);
  }

  pushMatrix();
  translate(shakeX, 0);

  y += PAD;
  float cx = W / 2;
  float cardY = y + 32 * dp;
  float cardH = H * 0.47;
  color glowCol = correct ? C_SUCCESS : C_DANGER;

  // Glow
  float ga = 0.5 + 0.5 * sin(glowPulse);
  for (int r = 6; r > 0; r--) {
    fill(red(glowCol), green(glowCol), blue(glowCol), ga * 16 * r * (resultAlpha / 255));
    rect(PAD - r * 9 * dp, cardY - r * 9 * dp, W - PAD * 2 + r * 18 * dp, cardH + r * 18 * dp, CARD_R + r * 9 * dp);
  }

  fill(C_SURFACE, resultAlpha);
  rect(PAD, cardY, W - PAD * 2, cardH, CARD_R);

  stroke(red(glowCol), green(glowCol), blue(glowCol), ga * 220 * (resultAlpha / 255));
  strokeWeight(3 * dp);
  noFill();
  rect(PAD, cardY, W - PAD * 2, cardH, CARD_R);
  noStroke();

  // Result text
  fill(glowCol, resultAlpha);
  textSize(34 * sp);
  textAlign(CENTER, CENTER);
  pushMatrix();
  translate(cx, cardY + cardH * 0.29);
  scale(resultScale);
  text(correct ? "CORRECT" : "INCORRECT", 0, 0);
  popMatrix();

  fill(C_TEXT, resultAlpha * 0.92);
  textSize(14.5 * sp);
  text(correct ? "Excellent identification" : "Sensor reading differs", cx, cardY + cardH * 0.49);

  // Info
  String yourPick = sortChoice.equals("fish") ? "FISH" : "GARBAGE";
  String detected = actualColor.equals("red") ? "RED (FISH)" : "GREEN (GARBAGE)";
  float infoY = cardY + cardH * 0.62;

  fill(C_GLASS);
  rect(PAD * 2, infoY, W - PAD * 4, 42 * dp, 12 * dp);
  fill(C_MUTED, resultAlpha);
  textSize(11.5 * sp);
  textAlign(LEFT, CENTER);
  text("Your choice:", PAD * 3, infoY + 21 * dp);
  fill(glowCol, resultAlpha);
  text(yourPick, PAD * 3 + 92 * dp, infoY + 21 * dp);
  fill(C_MUTED, resultAlpha);
  textAlign(RIGHT, CENTER);
  text("Sensor: " + detected, W - PAD * 3, infoY + 21 * dp);

  fill(C_GOLD, resultAlpha);
  textSize(17 * sp);
  text("Score: " + score + " / " + totalRounds, cx, cardY + cardH * 0.81);

  popMatrix();

  // Next button
  float btnY = cardY + cardH + PAD * 1.2;
  drawPrimaryBtn("NEXT ROUND", PAD, btnY, W - PAD * 2, BTN_H, C_PRIMARY, C_BG, shootBtnAnim, true);
}

// ============================================================
//  SHOOTING SCREEN — Premium Launch Button Only
// ============================================================
void drawShootingScreen(float y) {
  float btnW = W * 0.72;
  float btnH = BTN_H * 1.9;

  float btnX = (W - btnW) / 2;
  float btnY = (H - btnH) / 2;

  drawLaunchButton(btnX, btnY, btnW, btnH);
}

// Creative Professional Launch Button
void drawLaunchButton(float x, float y, float w, float h) {
  float cx = x + w / 2;
  float cy = y + h / 2;

  pushMatrix();
  translate(cx, cy);
  scale(shootBtnAnim);
  translate(-cx, -cy);

  // Flash glow only when button is pressed (shootBtnAnim < 0.99 means recently pressed)
  float pressFlash = max(0, (1.0 - shootBtnAnim) * 6);  // fades quickly after press
  if (pressFlash > 0) {
    for (int r = 3; r > 0; r--) {
      fill(red(C_DANGER), green(C_DANGER), blue(C_DANGER), pressFlash * 22 * r);
      rect(x - r * 6 * dp, y - r * 6 * dp, w + r * 12 * dp, h + r * 12 * dp, CARD_R + r * 7 * dp);
    }
  }

  fill(red(C_DANGER), green(C_DANGER), blue(C_DANGER), 42 + pressFlash * 30);
  rect(x, y, w, h, CARD_R);

  stroke(C_DANGER, 80 + pressFlash * 175);
  strokeWeight(2.8 * dp);
  noFill();
  rect(x, y, w, h, CARD_R);
  noStroke();

  fill(255);
  textSize(30 * sp);
  textAlign(CENTER, CENTER);
  text("SHOOT", cx, cy);

  popMatrix();
}

// ============================================================
//  HELPERS
// ============================================================
void drawSectionHeader(String title, String sub, float y) {
  fill(C_PRIMARY);
  rect(PAD, y + 3 * dp, 5 * dp, 22 * dp, 3 * dp);

  fill(C_TEXT);
  textSize(19 * sp);
  textAlign(LEFT, CENTER);
  text(title, PAD + 18 * dp, y + 13 * dp);

  fill(C_MUTED);
  textSize(12 * sp);
  text(sub, PAD + 18 * dp, y + 33 * dp);
}

void drawChoiceCard(String label, String sub, float x, float y, float w, float h,
                    boolean selected, color col, float anim) {
  float cx = x + w / 2, cy = y + h / 2;
  pushMatrix();
  translate(cx, cy);
  scale(anim);
  translate(-cx, -cy);

  if (selected) {
    fill(col, 42);
    rect(x, y, w, h, CARD_R);
    stroke(col);
    strokeWeight(2.8 * dp);
    noFill();
    rect(x, y, w, h, CARD_R);
  } else {
    fill(C_GLASS);
    rect(x, y, w, h, CARD_R);
    stroke(C_BORDER);
    strokeWeight(1 * dp);
    noFill();
    rect(x, y, w, h, CARD_R);
  }
  noStroke();

  fill(selected ? color(255) : C_TEXT);
  textSize(24 * sp);
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h * 0.44);

  fill(selected ? color(red(col), green(col), blue(col), 230) : C_MUTED);
  textSize(11 * sp);
  text(sub, x + w / 2, y + h * 0.69);

  popMatrix();
}

void drawGlassInfoRow(String label, String val, color valCol, float y) {
  fill(C_GLASS);
  rect(PAD, y, W - PAD * 2, 46 * dp, 12 * dp);
  stroke(C_BORDER);
  strokeWeight(0.8 * dp);
  noFill();
  rect(PAD, y, W - PAD * 2, 46 * dp, 12 * dp);
  noStroke();

  fill(C_MUTED);
  textSize(11 * sp);
  textAlign(LEFT, CENTER);
  text(label, PAD + 16 * dp, y + 23 * dp);

  fill(valCol);
  textSize(12 * sp);
  textAlign(RIGHT, CENTER);
  text(val, W - PAD - 16 * dp, y + 23 * dp);
}

void drawPrimaryBtn(String label, float x, float y, float w, float h, color bg, color fg, float anim, boolean active) {
  float cx = x + w / 2, cy = y + h / 2;
  pushMatrix();
  translate(cx, cy);
  scale(anim);
  translate(-cx, -cy);

  if (active) {
    float ga = 0.45 + 0.55 * sin(glowPulse);
    for (int r = 3; r > 0; r--) {
      fill(red(bg), green(bg), blue(bg), ga * 21 * r);
      rect(x - r * 6 * dp, y - r * 6 * dp, w + r * 12 * dp, h + r * 12 * dp, CARD_R + r * 6 * dp);
    }
    fill(bg);
    rect(x, y, w, h, CARD_R);
    fill(255, 255, 255, 38);
    rect(x, y, w, h * 0.48, CARD_R, CARD_R, 0, 0);
  } else {
    fill(bg);
    rect(x, y, w, h, CARD_R);
  }

  stroke(255, 65);
  strokeWeight(1.4 * dp);
  noFill();
  rect(x, y, w, h, CARD_R);
  noStroke();

  fill(fg);
  textSize(16 * sp);
  textAlign(CENTER, CENTER);
  text(label, x + w / 2, y + h / 2);
  popMatrix();
}

void drawBtPingIndicator(float y) {
  float dotSpacing = 16 * dp;
  float total = dotSpacing * 5;
  float sx = W / 2 - total / 2;
  for (int i = 0; i < 5; i++) {
    float phase = energyPulse - i * 0.45;
    float a = btConnected ? (110 + 115 * sin(phase)) : 35;
    fill(btConnected ? C_CYAN : C_MUTED, a);
    ellipse(sx + i * dotSpacing, y + 14 * dp, 6 * dp, 6 * dp);
  }
  fill(C_MUTED, 110);
  textSize(11 * sp);
  textAlign(CENTER, CENTER);
  text(btConnected ? "LIVE TRANSMISSION" : "OFFLINE", W / 2, y + 34 * dp);
}

// ============================================================
//  TRANSITION & TOAST
// ============================================================
void drawTransition() {
  if (!transIn && transAlpha <= 0) return;
  if (transIn) {
    transAlpha = lerp(transAlpha, 255, 0.24);
    if (transAlpha > 240) {
      screen = transTarget;
      transIn = false;
      if (screen == 1) { resultAlpha = 0; resultScale = 0.6; }
    }
  } else {
    transAlpha = lerp(transAlpha, 0, 0.19);
  }
  fill(0, 0, 0, transAlpha);
  rect(0, 0, W, H);
}

void goToScreen(int target) {
  if (transIn || screen == target) return;
  transTarget = target;
  transIn = true;
}

void drawToast() {
  if (toastTimer <= 0) return;
  toastTimer--;
  float a = min(255, toastTimer * 9);
  float tw = min(textWidth(toastMsg) + 52 * dp, W - PAD * 2);
  float ty = H * 0.88;
  fill(C_SURFACE, a);
  rect(W / 2 - tw / 2, ty, tw, 42 * dp, 24 * dp);
  stroke(C_BORDER);
  strokeWeight(1 * dp);
  noFill();
  rect(W / 2 - tw / 2, ty, tw, 42 * dp, 24 * dp);
  noStroke();
  fill(C_TEXT, a);
  textSize(13 * sp);
  textAlign(CENTER, CENTER);
  text(toastMsg, W / 2, ty + 21 * dp);
}

void showToast(String msg) {
  toastMsg = msg;
  toastTimer = 160;
}

void decayAnimations() {
  connectAnim = lerp(connectAnim, 1.0, 0.18);
  fishAnim = lerp(fishAnim, 1.0, 0.18);
  garbAnim = lerp(garbAnim, 1.0, 0.18);
  shootBtnAnim = lerp(shootBtnAnim, 1.0, 0.18);
}

// ============================================================
//  TOUCH HANDLING
// ============================================================
void mousePressed() {
  if (transIn || transAlpha > 35) return;

  float mx = mouseX, my = mouseY;

  // Connect button
  float bw = 108 * dp, bh = 32 * dp;
  float bx = W - PAD - bw, by = STATUS_H / 2 - bh / 2;
  if (mx > bx && mx < bx + bw && my > by && my < by + bh) {
    connectAnim = 0.86;
    toggleBluetooth();
    return;
  }

  // Tabs
  if (my > STATUS_H && my < STATUS_H + TAB_H) {
    goToScreen(mx < W / 2 ? 0 : 2);
    return;
  }

  if (screen == 0) handleSortTouch(mx, my);
  else if (screen == 1) handleResultTouch(mx, my);
  else if (screen == 2) handleShootTouch(mx, my);
}

void handleSortTouch(float mx, float my) {
  float cardY = STATUS_H + TAB_H + PAD * 1.1 + 78 * dp;
  float cardW = (W - PAD * 3) / 2;
  float cardH = H * 0.285;

  if (mx > PAD && mx < PAD + cardW && my > cardY && my < cardY + cardH) {
    sortChoice = "fish";
    fishAnim = 0.86;
    showToast("Fish selected");
    return;
  }
  float gx = PAD * 2 + cardW;
  if (mx > gx && mx < gx + cardW && my > cardY && my < cardY + cardH) {
    sortChoice = "garbage";
    garbAnim = 0.86;
    showToast("Garbage selected");
    return;
  }

  float btnY = cardY + cardH + 58 * dp + PAD * 1.4;
  if (my > btnY && my < btnY + BTN_H && !sortChoice.isEmpty()) {
    if (!btConnected) { showToast("Connect Bluetooth first"); return; }
    if (sortChoice.equals("fish")) btSend("FISH:512\n");
    else btSend("GARB:1024\n");
    showToast("Command sent");
    if (!actualColor.isEmpty()) resolveResult();
  }
}

void handleResultTouch(float mx, float my) {
  float cardY = STATUS_H + TAB_H + PAD + 32 * dp;
  float cardH = H * 0.47;
  float btnY = cardY + cardH + PAD * 1.2;
  if (my > btnY && my < btnY + BTN_H) {
    sortChoice = "";
    actualColor = "";
    resultShown = false;
    setBallLocation("Waiting for signal...");
    goToScreen(0);
  }
}

void handleShootTouch(float mx, float my) {
  float btnY = STATUS_H + TAB_H + PAD * 1.2 + 88 * dp + 40 * dp;
  float btnH = BTN_H * 2.05;
  if (my > btnY && my < btnY + btnH) {
    shootBtnAnim = 0.86;
    if (!btConnected) { showToast("Connect Bluetooth first"); return; }
    int pwmVal = round(launchSpeed * 255.0 / 100);
    btSend("SHOOT:" + pwmVal + "\n");
    showToast("Launch command sent");
    spawnParticles(W / 2, btnY + btnH / 2, C_DANGER, 45);
  }
}

// ============================================================
//  RESULT LOGIC
// ============================================================
void resolveResult() {
  totalRounds++;
  boolean fishGuess = sortChoice.equals("fish");
  boolean greenBall = actualColor.equals("green");
  correct = (fishGuess && greenBall) || (!fishGuess && !greenBall);

  if (correct) {
    score++;
    spawnParticles(W / 2, H * 0.42, C_SUCCESS, 55);
    showToast("Correct identification!");
  } else {
    shakeDecay = 16;
    showToast("Sensor override");
  }
  resultShown = true;
  goToScreen(1);
}

// ============================================================
//  BLUETOOTH
// ============================================================
void toggleBluetooth() {
  if (btConnected) disconnectBT();
  else connectBT();
}

void connectBT() {
  try {
    if (btAdapter == null) { showToast("Bluetooth unavailable"); return; }
    if (!btAdapter.isEnabled()) { showToast("Enable Bluetooth"); return; }
    showToast("Connecting...");
    BluetoothDevice device = btAdapter.getRemoteDevice(MAC_ADDRESS);
    btSocket = device.createRfcommSocketToServiceRecord(SPP_UUID);
    btAdapter.cancelDiscovery();
    btSocket.connect();
    btOutput = btSocket.getOutputStream();
    btInput = btSocket.getInputStream();
    btConnected = true;
    showToast("Connected successfully");
  } catch (Exception e) {
    btConnected = false;
    showToast("Connection failed");
  }
}

void disconnectBT() {
  try { if (btSocket != null) btSocket.close(); } catch (Exception e) {}
  btConnected = false;
  showToast("Disconnected");
}

void btSend(String msg) {
  if (!btConnected || btOutput == null) return;
  try {
    btOutput.write(msg.getBytes());
  } catch (Exception e) {
    btConnected = false;
    showToast("Connection lost");
  }
}

void readBluetooth() {
  if (!btConnected || btInput == null) return;
  try {
    int avail = btInput.available();
    for (int i = 0; i < avail && i < 80; i++) {
      char c = (char) btInput.read();
      if (c == '\n') {
        processArduinoMessage(btIncoming.trim());
        btIncoming = "";
      } else btIncoming += c;
    }
  } catch (Exception e) {
    btConnected = false;
  }
}

void processArduinoMessage(String msg) {
  if (msg.startsWith("LOC:")) {
    setBallLocation("Ball: " + msg.substring(4));
  } else if (msg.startsWith("COLOR:")) {
    actualColor = msg.substring(6).toLowerCase().trim();
    if (!sortChoice.isEmpty() && screen == 0 && !resultShown) resolveResult();
    setBallLocation(actualColor.equals("red") ? "Ball: Sea Path" : "Ball: Shooter Path");
  } else if (msg.equals("STAGE:SHOOT")) {
    setBallLocation("Ball: Shooting Module");
    goToScreen(2);
  } else if (msg.equals("STAGE:SORT")) {
    setBallLocation("Ball: Sorting Module");
    goToScreen(0);
  } else if (msg.equals("STAGE:LIFT")) {
    setBallLocation("Ball: Lifting Module");
  }
}

void setBallLocation(String loc) {
  if (loc.equals(ballLocation)) return;
  ballLocation = loc;
  ballLocAlpha = 40;
  ballLocSlide = 42 * dp;
}
