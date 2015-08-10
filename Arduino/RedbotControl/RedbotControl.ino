#include <Wire.h>
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_PWMServoDriver.h"

// Create the motor shield object with the default I2C address
Adafruit_MotorShield AFMS = Adafruit_MotorShield(); 
// Or, create it with a different I2C address (say for stacking)
// Adafruit_MotorShield AFMS = Adafruit_MotorShield(0x61); 

// Select which 'port' M1, M2, M3 or M4. In this case, M1
Adafruit_DCMotor *leftWheelMotor = AFMS.getMotor(3);
// You can also make another motor on port M2
Adafruit_DCMotor *rightWheelMotor = AFMS.getMotor(4);

/* Uncomment if you are using the 2 IR Sensors
int leftSensorPin = 0;
int rightSensorPin = 3;

int leftSensorValue = 0;
int rightSensorValue = 0;
int sendSensorData = 0;
*/

void setup() {
  Serial.begin(57600);

  AFMS.begin();  // create with the default frequency 1.6KHz
  //AFMS.begin(1000);  // OR with a different frequency, say 1KHz
}

void loop() {

  while ( Serial.available() == 3 )
  {
    // read out command and data
    byte data0 = Serial.read();
    delay(10);
    byte leftWheelVelocity = Serial.read(); //left wheel speed
    delay(10);
    byte rightWheelVelocity = Serial.read(); //right wheel speed
       
    if (data0 == 0x71)  // Command is to control digital out pin
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      rightWheelMotor->setSpeed(rightWheelVelocity);      
      leftWheelMotor->run(FORWARD);
      rightWheelMotor->run(FORWARD);
    }
    else if (data0 == 0x72)
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      rightWheelMotor->setSpeed(rightWheelVelocity);
      leftWheelMotor->run(FORWARD);
      rightWheelMotor->run(BACKWARD);
    }
    else if (data0 == 0x73)
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      rightWheelMotor->setSpeed(rightWheelVelocity);
      leftWheelMotor->run(BACKWARD);
      rightWheelMotor->run(BACKWARD);
    }
    else if (data0 == 0x74)
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      rightWheelMotor->setSpeed(rightWheelVelocity);
      leftWheelMotor->run(BACKWARD);
      rightWheelMotor->run(FORWARD);
    }
    else if (data0 == 0x75)
    {
      rightWheelMotor->setSpeed(rightWheelVelocity);
      leftWheelMotor->run(RELEASE);
      rightWheelMotor->run(FORWARD);
    }
    else if (data0 == 0x76)
    {
      leftWheelMotor->run(RELEASE);
      rightWheelMotor->run(RELEASE);
    }
    else if (data0 == 0x77)
    {
      rightWheelMotor->setSpeed(rightWheelVelocity);
      leftWheelMotor->run(RELEASE);
      rightWheelMotor->run(BACKWARD);
    }
    else if (data0 == 0x78)
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      leftWheelMotor->run(FORWARD);
      rightWheelMotor->run(RELEASE);
    }
    else if (data0 == 0x79)
    {
      leftWheelMotor->setSpeed(leftWheelVelocity);
      leftWheelMotor->run(BACKWARD);
      rightWheelMotor->run(RELEASE);
    }
  }
  /* Uncomment if you are using the 2 IR Sensors
  if (sendSensorData == 1)
  {
    //Read the distance analog sensors
    leftSensorValue = analogRead(leftSensorPin);
    rightSensorValue = analogRead(rightSensorPin);
  
    //compute the left distance
    if ( leftSensorValue < 80 )
    {
      leftSensorValue = 80;
    }
    else if ( leftSensorValue > 500 )
    {
      leftSensorValue = 500;
    }
    float leftDistance = 4800.0/(((float)leftSensorValue) - 20.0);
  
  
    //compute the right distance
    if ( rightSensorValue < 80 )
    {
      rightSensorValue = 80;
    }
    else if ( rightSensorValue > 500 )
    {
      rightSensorValue = 500;
    }
    float rightDistance = 4800.0/(((float)rightSensorValue) - 20.0);
    
    // if the value is not -1 then it is between 10cm and 80cm
    // I have to translate this into bytes
    
    float normalizedLeftDistance = (leftDistance - 10.0)/70.0;
    byte leftDistanceByte = (byte) (min(255, (byte) (normalizedLeftDistance*255.0)));
    
    float normalizedRightDistance = (rightDistance - 10.0)/70.0;
    byte rightDistanceByte = (byte) (min(255, (byte) (normalizedRightDistance*255.0)));
    
    byte data[] = {0xBC, leftDistanceByte, rightDistanceByte};
    Serial.write(data, 3);
    
    sendSensorData = 0;
  }
  else
  {
    sendSensorData = 1;
  }
  */
  delay(100);
}
