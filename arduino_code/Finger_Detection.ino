#include <SoftwareSerial.h>

// Define SoftwareSerial pins for the fingerprint module:
SoftwareSerial fingerSerial(8, 9); // (RX, TX)

void setup() {
  Serial.begin(9600);
  // Module default baud rate is 57600bps
  fingerSerial.begin(57600);
  delay(100);
  Serial.println("R303S Fingerprint Module Test");
}

void loop() {
  // Step 1: Send command to capture fingerprint image (GenImg: 0x01)
  sendCommand(0x01, NULL, 0);
  byte ack = waitForAck();
  if (ack == 0x00) {
    Serial.println("Finger detected and image captured.");
    
    // Step 2: Send command to upload the image (UpImage: 0x0A)
    sendCommand(0x0A, NULL, 0);
    
    // Read the raw image data packet (this example simply prints it in HEX)
    readImageData();
  } else {
    Serial.print("No finger detected or error, ack code: 0x");
    Serial.println(ack, HEX);
  }
  delay(3000); // Wait before trying again
}

// Function to send a command packet to the module
void sendCommand(byte instruction, byte* params, int paramLen) {
  // Packet structure:
  // Header (2 bytes) + Address (4 bytes, default 0xFFFFFFFF) + PID (1 byte) +
  // Length (2 bytes: instruction + parameters + 2 checksum bytes) +
  // Instruction (1 byte) + Parameters (if any) + Checksum (2 bytes)
  
  // Header:
  byte header[2] = {0xEF, 0x01};
  // Default Address:
  byte address[4] = {0xFF, 0xFF, 0xFF, 0xFF};
  // PID for command packet:
  byte pid = 0x01;
  // Calculate packet length: Instruction (1) + params + checksum (2)
  int packetLength = 1 + paramLen + 2;
  byte lengthHigh = (packetLength >> 8) & 0xFF;
  byte lengthLow  = packetLength & 0xFF;

  // Send header, address, PID, and length:
  fingerSerial.write(header, 2);
  fingerSerial.write(address, 4);
  fingerSerial.write(pid);
  fingerSerial.write(lengthHigh);
  fingerSerial.write(lengthLow);
  
  // Send the instruction code:
  fingerSerial.write(instruction);
  
  // Send any parameters:
  if (paramLen > 0 && params != NULL) {
    for (int i = 0; i < paramLen; i++) {
      fingerSerial.write(params[i]);
    }
  }
  
  // Compute checksum: sum of PID, lengthHigh, lengthLow, instruction, and any parameters.
  uint16_t checksum = pid + lengthHigh + lengthLow + instruction;
  if (paramLen > 0 && params != NULL) {
    for (int i = 0; i < paramLen; i++) {
      checksum += params[i];
    }
  }
  byte checksumHigh = (checksum >> 8) & 0xFF;
  byte checksumLow  = checksum & 0xFF;
  
  // Send checksum:
  fingerSerial.write(checksumHigh);
  fingerSerial.write(checksumLow);
}

// Function to wait for an acknowledgment packet from the module
byte waitForAck() {
  unsigned long start = millis();
  // Wait for a minimal ack packet (approx. 10 bytes) with a timeout
  while (fingerSerial.available() < 10 && (millis() - start) < 2000);
  if (fingerSerial.available() >= 10) {
    byte ackPacket[10];
    for (int i = 0; i < 10; i++) {
      ackPacket[i] = fingerSerial.read();
    }
    // In the acknowledgment packet, the confirmation code is typically located after:
    // Header (2) + Address (4) + PID (1) + Length (2) = 9 bytes; the 10th byte is the confirmation.
    byte confCode = ackPacket[9];
    return confCode;
  }
  return 0xFF; // Return an error code if timeout occurs
}

// Function to read and print image data in HEX format
void readImageData() {
  Serial.println("Reading image data:");
  // In practice, you might know the expected image size from the manual.
  // Here, we just print any available bytes.
  while (fingerSerial.available()) {
    byte data = fingerSerial.read();
    Serial.print(data, HEX);
    Serial.print(" ");
  }
  Serial.println();
}
