# PID DC motor speed controller with PIC microcontroller
## Introduction 
- This is an RS232-based PID DC motor controller.
- The PID controller is program in inside the PIC microcontroller, where as the motor model is integrated with the GUI in MATLAB.
- The motor transfer function is modelised with state-space representation. Because the microcontrollers work in the time domain, so the motor model must be in that domain, too. That is why the state variable method is selected here.
## PIC Microcontroller suitable for this project
- PIC16F877
- PIC16F877A
- PIC16F887
## Software used
- MATLAB R2021b: design the controller's GUI and model the DC motor.
- PIC CCS C 5.115: program in C language and generate .hex file for Proteus.
- Proteus 8.12: simulate the PIC16F877 microcontroller and RS232 serial ports.
- Virtual Serial Port Driver 6.9 by Eltima Software: create virtual serial ports and pair them.
## How to use
- Use VSPD to create and pair two virtual COM ports: COM1 and COM2 (can be changed)
- Run the GUI.m file in MATLAB (version R2021b or above) to open the GUI.
- Start the simulation in Proteus.
- To connect/disconnect the GUI with Proteus, press the "Connect/Disconnect" button accordingly.
- Select the simulation duration as desired. Enter the desired motor speed and press start to send that value to the microcontroller.
- Once the simulation starts, the value of the current speed will be plotted on the graph, for easier observation.
- To change the desired speed value during the simulation, simply enter a new speed value and press the "Send" button.
- The microcontroller will automatically reset its original state after the simulation is done and is ready for the next use.
## Demonstration
- Simulation video: https://drive.google.com/file/d/1SYGGCjXtbVsDfEm9NgBektin4EQ8IAXG/view?usp=sharing
## Reference
- Matab: https://www.mathworks.com/products/new_products/release2021b.html
- Motor paramters: https://ctms.engin.umich.edu/CTMS/index.php?example=MotorSpeed&section=SystemModeling
- PIC CCS C: https://www.ccsinfo.com/compilers.php
- Proteus: https://www.labcenter.com/
- VSPD: https://www.eltima.com/products/vspdxp/

