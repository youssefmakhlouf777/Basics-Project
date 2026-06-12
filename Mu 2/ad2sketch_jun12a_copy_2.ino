#include <Stepper.h>
#include <LiquidCrystal_I2C.h>

const int stepsPerRevolution = 2048;

Stepper myStepper(stepsPerRevolution, 10, 12, 11, 13);

LiquidCrystal_I2C lcd(0x27, 16, 2);

int S0 = 2;
int S1 = 3;
int S2 = 4;
int S3 = 5;
int sensorOut = 6;

int base = 0;
int red = 0;
int green = 0;
int blue = 0;

void setup() {

  Serial.begin(9600);

  pinMode(S0, OUTPUT);
  pinMode(S1, OUTPUT);
  pinMode(S2, OUTPUT);
  pinMode(S3, OUTPUT);
  pinMode(sensorOut, INPUT);

  digitalWrite(S0, HIGH);
  digitalWrite(S1, LOW);

  myStepper.setSpeed(10);

  lcd.init();
  lcd.backlight();

  lcd.setCursor(0,0);
  lcd.print("System Ready");
}

void loop() {

  digitalWrite(S2, LOW);
  digitalWrite(S3, LOW);
  red = pulseIn(sensorOut, LOW);

  digitalWrite(S2, HIGH);
  digitalWrite(S3, HIGH);
  green = pulseIn(sensorOut, LOW);

  digitalWrite(S2, LOW);
  digitalWrite(S3, HIGH);
  blue = pulseIn(sensorOut, LOW);

  Serial.print("R: ");
  Serial.print(red);
  Serial.print(" G: ");
  Serial.print(green);
  Serial.print(" B: ");
  Serial.println(blue);

  blue = blue + 50;

  if (red < green && red < blue) {

    Serial.println("red detected!");

    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("It is Fish");

    myStepper.step(-512);
    delay(1000);
    myStepper.step(512);
    delay(1000);
  }

  if (green < red && green + 40 < blue) {

    Serial.println("green detected!");

    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("It is Waste");

    myStepper.step(1024);
    delay(1000);
    myStepper.step(-1024);
    delay(1000);
  }

  delay(500);
}