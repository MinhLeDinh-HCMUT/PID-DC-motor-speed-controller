# PID DC motor speed controller 
## Introduction 
- This is a RS232-based PID DC motor controller.
- The motor transfer function is modelised with state-space representation in Matlab. Because the microcontrollers work in time-domain, so the motor model must be in that domain, too. That is why the state variable method is selected.
## PIC Microcontroller suitable for this project
- PIC16F877
- PIC16F877A
- PIC16F887
## Software used
- MATLAB R2021b: model the DC motor.
- Proteus 8.12: simulate the PIC16F877 microcontroller and RS232 serial port.
- Virtual Serial Port Driver 6.9 by Eltima Software: create virtual serial port and pair them

- 
