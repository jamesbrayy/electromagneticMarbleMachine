#include <U8g2lib.h>
#include <math.h>
#include <FreqMeasure.h>

// Initialize display with a single font for efficiency
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, -1, A5, A4);

uint16_t capVoltage = 0, setVoltage = 0; // Changed from float to uint16_t
uint16_t frequency = 0; // Changed from float to uint16_t

const uint8_t potentiometer = A0, receiverIR = A1, hallEffect = A2;
const uint8_t buttonPin = 7, bleed = 9, dischargePin = 10, chargePin = 11, solenoidPin = 12, indicatorLED = 13;
const uint8_t debounce = 20, holdTime = 2000;

bool mode = false;
double sum=0;
int count=0;

int hallValue;
int b = 0; // value read from button
int blast = 0; // buffered value of the button's previous state
unsigned long bdown; // time the button was pressed down
unsigned long bup; // time the button was released

#define centreX(text) ((128 - u8g2.getStrWidth(text)) / 2)

void setup() {
  Serial.begin(57600);  // Start serial communication
  FreqMeasure.begin();

  pinMode(bleed, OUTPUT);
  pinMode(buttonPin, INPUT);
  pinMode(chargePin, OUTPUT);
  pinMode(dischargePin, OUTPUT);
  pinMode(indicatorLED, OUTPUT);
  pinMode(solenoidPin, OUTPUT);
  
  digitalWrite(buttonPin, HIGH); // pull-up 20k
  digitalWrite(indicatorLED, LOW);
  
  u8g2.begin();  // Initialize the display
  u8g2.clearBuffer();  // Clear the display buffer
  
  // Set a single font for efficiency
  u8g2.setFont(u8g2_font_profont12_tr);  
  u8g2.setCursor(30, 20);  
  u8g2.print(F("James Bray's"));  
  u8g2.setCursor(1, 40);  
  u8g2.setFont(u8g2_font_profont17_tr);
  u8g2.print(F("Marble Machine"));  
  u8g2.setCursor(34, 60);  
  u8g2.setFont(u8g2_font_profont10_tr);  
  u8g2.print(F("2024 11A_EST1"));  
  u8g2.sendBuffer();  
  delay(3000);  
  u8g2.clearBuffer();  
}

void charging() {
  digitalWrite(chargePin, HIGH);
  u8g2.setFont(u8g2_font_profont12_tr); 
  u8g2.setCursor(centreX("Set Voltage: 000 V"), 25);
  u8g2.print(F("Set Voltage: "));
  u8g2.print(setVoltage);  
  u8g2.print(F(" V"));

  u8g2.setCursor(centreX("Cap Voltage: 000 V"), 40);
  u8g2.print(F("Cap Voltage: "));
  
  if (capVoltage < 20) {
    u8g2.print(F("<20 V"));
  } else {
    u8g2.print(capVoltage);  
    u8g2.print(F(" V"));
  }

  u8g2.setBitmapMode(1);
  u8g2.drawFrame(12, 44, 104, 18);  
  u8g2.drawBox(14, 46, (capVoltage * 100 / setVoltage), 14);  
}

void automatic() {
  digitalWrite(chargePin, LOW);
  discharge();
}

void manual() {
  digitalWrite(chargePin, LOW);
  u8g2.clearBuffer();
  mode = false;
  drawHeader();
  u8g2.setFont(u8g2_font_profont12_tr);
  u8g2.setCursor(centreX("Press the button to"), 26);
  u8g2.print(F("Press the button to"));
  u8g2.setCursor(centreX("manually discharge."), 38);
  u8g2.print(F("manually discharge."));
  u8g2.sendBuffer();

  // Wait until the button is released
  while (digitalRead(buttonPin) == HIGH);

  // Debounce: wait for stable LOW state
  delay(debounce);

  // Check if the button is released (button is LOW)
  if (digitalRead(buttonPin) == LOW) {
    unsigned long startTime = millis(); // Start timer after button release

    while (true) {
      // Wait for the button to be pressed again (HIGH state)
      while (digitalRead(buttonPin) == LOW) {
        // Check if 5 seconds have passed since the button was released
        if (millis() - startTime > 5000) {
          return; // Exit the function after 5 seconds of no input
        }
      }

      // Button pressed, debounce
      delay(debounce);

      // If button is pressed (HIGH state) within 5 seconds, proceed with discharge
      if (digitalRead(buttonPin) == HIGH) {
        discharge(); // Call discharge function
        break;
      }
    }
  }
}


void discharge() {
  for (int8_t i = 3; i > 0; i--) {
    u8g2.clearBuffer();
    drawHeader();
    u8g2.setCursor(20, 25);
    u8g2.setFont(u8g2_font_profont12_tr);
    u8g2.print(F("Discharging in:"));
    u8g2.setCursor(56, 50);
    u8g2.setFont(u8g2_font_profont29_tr);
    u8g2.print(i);
    u8g2.sendBuffer();
    delay(1000);  
  }
  u8g2.clearBuffer();
  drawHeader();
  u8g2.setCursor(16, 42);
  u8g2.setFont(u8g2_font_profont17_tr);
  u8g2.print(F("DISCHARGING"));
  u8g2.sendBuffer();
  digitalWrite(solenoidPin, HIGH);
  delay(1000); // change this to a more respectable value later
  digitalWrite(solenoidPin, LOW);
  while true;
    if (analogRead(receiverIR) > 512) {
      digitalWrite(dischargePin, HIGH);
      delay(1000);
      digitalWrite(dischargePin, LOW);
      break;
    }
}

void drawHeader() {
  u8g2.setFont(u8g2_font_profont10_tr);
  u8g2.drawLine(0, 12, 128, 12);
  u8g2.setCursor(0, 10);
  u8g2.print(mode ? F("Automatic Mode") : F("Manual Mode"));
  u8g2.setCursor(100, 10);
  u8g2.print(frequency);
}

void checkButton() {
  static enum { IDLE, PRESSED, HELD } buttonState = IDLE;
  b = digitalRead(buttonPin);
  
  switch (buttonState) {
    case IDLE:
      // Detect button press (transition from LOW to HIGH for normally closed)
      if (b == HIGH && (millis() - bup) > debounce) {
        bdown = millis(); // Record when the button was pressed down
        buttonState = PRESSED;
      }
      break;

    case PRESSED:
      // Check if button has been held long enough for a long press
      if (b == HIGH && (millis() - bdown) >= holdTime) {
        manual(); // Trigger the long press action
        buttonState = HELD;
      }
      // If the button is released before holdTime, it's a short press
      else if (b == LOW) {
        if ((millis() - bdown) > debounce) {
          mode = !mode; // Toggle mode on short press
        }
        bup = millis(); // Record the time when the button was released
        buttonState = IDLE;
      }
      break;

    case HELD:
      // Wait for the button to be released after a long press
      if (b == LOW) {
        bup = millis(); // Record when the button was released
        buttonState = IDLE;
      }
      break;
  }

  blast = b; // Update the last button state
}




void loop() {
  static float f;
  delay(10);
  u8g2.clearBuffer();
  
  // Ensure you only calculate frequency after a certain interval
  if (FreqMeasure.available()) {
    // average several reading together
    f = FreqMeasure.read();
    sum = sum + f;
    count = count + 1;
    if (count > 1) {
      frequency = FreqMeasure.countToFrequency(sum / count);
      sum = 0;
      count = 0;
    }
  }

  checkButton();
  drawHeader();
  
  hallValue = analogRead(hallEffect);  

  setVoltage = map(analogRead(potentiometer), 10, 1013, 20, 80) * 5;  
  capVoltage = (uint16_t)(47.05 * exp(0.002425 * frequency)) - 37.87;  
  if (setVoltage > capVoltage) {
    charging();
  } else {
    mode ? automatic() : manual();
  }
  
  u8g2.sendBuffer();
}
