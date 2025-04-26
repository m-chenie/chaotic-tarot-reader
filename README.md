# Chaotic Tarot Reader

A fusion of biometric security, hardware-based randomness, and symbolic visualization through tarot. This project integrates an R307 fingerprint sensor, an FPGA running a PRNG based on the Hénon map, and a Raspberry Pi 4 Model B to display personalized tarot cards.

---

## Overview

The Chaotic Tarot Reader is an interactive system that combines secure biometric authentication with chaotic pseudo-random number generation to deliver personalized tarot readings. By leveraging hardware components and cryptographic techniques, the system ensures both security and uniqueness in each interaction.

---

## System Architecture

1. **Biometric Authentication**:  
   - **R307 Fingerprint Sensor**: Captures the user's fingerprint.
   - **FPGA Processing**: Processes fingerprint data in hardware, applies SHA-256 hashing, and stores cryptographic hashes in BRAM to ensure tamper resistance.

2. **Entropy Generation**:  
   - **Hénon Map PRNG**: Utilizes entropy from the fingerprint and a light/temperature sensor to seed a 2D Hénon map, generating a pseudo-random number corresponding to a tarot card.

3. **Visualization**:  
   - **Raspberry Pi 4 Model B**: Receives the tarot card index via UART, maps it to a specific card, and displays the image along with interpretive keywords using a Python-based GUI.

---

## 3D Model & Hardware Components
The enclosure for the Chaotic Tarot Reader, referred to as the DSL Box, was designed in Autodesk Fusion 360 to house the various hardware components securely and efficiently. You can view the 3D model using the link here: https://a360.co/4jVf0f3
- The model includes compartments for the fingerprint sensor, LCD, and supporting electronics.
- Use the embedded viewer to rotate, zoom, and inspect the enclosure in 3D.
- Download is available directly from the link if you wish to modify or print the enclosure.

**These are the hardware components**
- **DSL Box**: Printed in PLA filament
- **FPGA**: Digilent Cmod A7 (Artix-7)
- **Microcontroller**: Arduino Uno
- **Fingerprint Sensor**: R307
- **Analog-to-Digital Converter**: MCP3202
- **Sensors**: Light/Temperature sensor connected to the ADC
- **Display**: LCD connected to Raspberry Pi
- **Communication**: UART interfaces between components

---

## Software Components

- **FPGA Modules**:
  - `henon_map_q31.v`: Implements a single iteration of the Hénon map using fixed-point arithmetic.
  - `henon_prng_top.v`: Controls multiple iterations of the Hénon map to generate a random number.
  - `uart_rx.v` & `uart_tx.v`: Handle UART communication for receiving fingerprint data and sending the tarot card index.

- **Arduino Sketch**:
  - Initiates fingerprint capture upon user interaction.

- **Raspberry Pi Python Script**:
  - Receives the tarot card index via UART.
  - Maps the index to a specific tarot card.
  - Displays the card image and associated keywords using a Tkinter-based GUI.

---

## Setup Instructions

1. **Hardware Assembly**:
   - Connect the R307 fingerprint sensor to the Arduino Uno.
   - Interface the Arduino with the FPGA via UART.
   - Connect the MCP3202 ADC and the light/temperature sensor to the FPGA.
   - Link the FPGA to the Raspberry Pi using UART (GPIO 15).
   - Attach the LCD display to the Raspberry Pi.

2. **FPGA Configuration**:
   - Use Xilinx Vivado to synthesize and program the FPGA with the provided Verilog modules.

3. **Arduino Setup**:
   - Upload the Arduino sketch to initiate fingerprint capture upon user interaction.

4. **Raspberry Pi Setup**:
   - Ensure Python 3 is installed along with the following libraries:
     - `tkinter`
     - `PIL` (Pillow)
     - `pyserial`
   - Place the tarot card images in the specified directory.
   - Run the Python script `tarot_gui_final.py` to start the GUI.

---

## Usage

1. **Fingerprint Capture**:
   - Place your finger on the R307 sensor.
   - The Arduino triggers the sensor to capture the fingerprint.

2. **Entropy Generation**:
   - The FPGA processes the fingerprint data and reads the light/temperature sensor.
   - Seeds the Hénon map PRNG with the collected entropy.
   - Generates a pseudo-random number corresponding to a tarot card index.

3. **Tarot Card Display**:
   - The Raspberry Pi receives the tarot card index via UART.
   - Maps the index to a specific tarot card.
   - Displays the card image and associated keywords on the LCD.

---
