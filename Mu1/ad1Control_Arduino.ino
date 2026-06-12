#include <SoftwareSerial.h>
#include <Servo.h>
#include <Wire.h> 
#include <LiquidCrystal_I2C.h> // مكتبة الشاشة

// Bluetooth pins
SoftwareSerial BT(0, 1);  // RX=0, TX=1

// L298N Motor pins
#define MOTOR_IN1  7
#define MOTOR_IN2  6
#define MOTOR_ENA  5    

String inputBuffer = "";

Servo lifting;
Servo gate;

// تعريف شاشة الـ LCD
LiquidCrystal_I2C lcd(0x27, 16, 2); 

int irSensor = 2;       
int buttonPin = 3;      
int servoLiftingPin = 9; 
int servoGatePin = 10;    

int startAngle = 132.5;   
int moveAngle = 30;     

// دالة لتحديث الكتابة على الشاشة بسهولة وتنظيفها
void printStatus(String line1, String line2) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(line1);
  lcd.setCursor(0, 1);
  lcd.print(line2);
}

// ============================================================
void setup() {
  pinMode(buttonPin, INPUT_PULLUP);
  Serial.begin(9600);
  BT.begin(9600);

  pinMode(MOTOR_IN1, OUTPUT);
  pinMode(MOTOR_IN2, OUTPUT);
  pinMode(MOTOR_ENA, OUTPUT);
  pinMode(irSensor, INPUT);

  // تشغيل الشاشة والترحيب
  lcd.init();
  lcd.backlight();
  printStatus("  Game Started  ", "   Ready...     ");
  delay(2000); 

  gate.attach(servoGatePin);
  lifting.attach(servoLiftingPin);

  lifting.write(startAngle);
  gate.write(180); 

  stopMotor();
  printStatus("Ball Status:", "Waiting...");
}

// ============================================================
void loop() {
  
  // 1. مرحلة البوابة (Gate)
  if (digitalRead(buttonPin) == LOW) {
    printStatus("Ball Status:", "Passing Gate"); 
    gate.write(0);
    delay(2000);
    gate.write(180);
    printStatus("Ball Status:", "Waiting...");
  }
  
  // 2. مرحلة الرفع (Lifting) ثم الفرز (Sorting)
  int sensorValue = digitalRead(irSensor);
  if (sensorValue == LOW) {
    // الكورة تدخل الـ Lifting
    printStatus("Ball Status:", "In Lifting"); 
    lifting.write(moveAngle);  
    delay(1000); // ينتظر ثانية وهي مرفوعة              
    
    lifting.write(startAngle); // يرجع السيرفو لمكانه
    delay(500); // ينتظر نصف ثانية (المجموع ثانية ونصف)
    
    // الآن بعد ثانية ونص تماماً، الكورة انتقلت للـ Sorting
    printStatus("Ball Status:", "In Sorting"); 
    delay(1000); // نترك الجملة ثانية على الشاشة لتقرأها
    
    printStatus("Ball Status:", "Waiting...");
  }

  // 3. قراءة بيانات البلوتوث
  while (BT.available()) {
    char c = (char)BT.read();
    if (c == '\n') {
      processCommand(inputBuffer);
      inputBuffer = "";
    } else {
      inputBuffer += c;
    }
  }
}

// ============================================================
void processCommand(String cmd) {
  cmd.trim();
  Serial.println("CMD: " + cmd);

  if (cmd.startsWith("FWD:")) {
    int speed = cmd.substring(4).toInt();
    speed = map(speed, 0, 100, 0, 255);
    moveForward(speed);
  }
  else if (cmd.startsWith("BWD:")) {
    int speed = cmd.substring(4).toInt();
    speed = map(speed, 0, 100, 0, 255);
    moveBackward(speed);
  }
  else if (cmd == "STOP") {
    stopMotor();
    printStatus("Ball Status:", "Waiting...");
  }
  else if (cmd.startsWith("SHOOT:")) {
    int pwm = constrain(cmd.substring(6).toInt(), 0, 255);
    shootBall(pwm);
  }
}

// ============================================================
void moveForward(int pwm) {
  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_ENA, pwm);
}

void moveBackward(int pwm) {
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, HIGH);
  analogWrite(MOTOR_ENA, pwm);
}

void stopMotor() {
  digitalWrite(MOTOR_IN1, LOW);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_ENA, 0);
}

// 4. مرحلة الرمي (Shooting)
void shootBall(int pwm) {
  printStatus("Ball Status:", "In Shooting"); 
  
  digitalWrite(MOTOR_IN1, HIGH);
  digitalWrite(MOTOR_IN2, LOW);
  analogWrite(MOTOR_ENA, pwm);
  delay(2000);
  stopMotor();
  
  printStatus("Ball Status:", "Waiting...");
}