# Continuous pattern implenmentation on Agilent 5500 AFM


The theoretical analysis of this implementation have not yet published. And you are welcome to contact: luoyuf@bu.edu 

The control algorithm contrains 2 states with the 1st one as the initialization, with 5 independent loops.

## The 2 states:

1. Initialization: In this state, users approach the tip to the sample with stepper motor using PicoView close loop control. Then release the control from PicoView to FPGA. The system writes parameters including the locations of the path from desktop files to a host-to-FPGA FIFO (first in, first out) buffer. Turn on the close loop control of all the axes. The system performs the following operations,

Read the location of the first initial location from the FIFO.
Set z-axis loop to deflection control mode.
Wait for |e_z(k)| reaches a settling criterion, then go to state 2.

2. xy-axis move: In this state, the system moves the tip following the continuous trajectory.

Set x_ref ; y_ref to the next location.
Wait for |e_x(k)|, |e_y(k)| reach a settling criterion. Go to state 2.




## The 5 loops:

1. x-piezo control loop  - control x-axis direction
2. y-piezo control loop  - control y-axis direction
3. z-piezo control loop  - control z-axis direction
4. state check control loop  - update x,y location
5. Data recording loop

## Data recording and reading
For all of this to work properly, data needs to packed into both `host-to-FPGA` and `fpga-to-host` in a specific format.

### host-to-FPGA
At the end of state 2, the next pixel location are read from host-to-FPGA FIFO with the following format:
[x position, y position].

### FPGA-to-host
Data are recording to FPGA-to-host FIFO with the following format:
[x position, y position, z position, direction signal].


## Host VI and Front Panel Controls

### User input
These are the most commanly used settings.
* `Z-control/Setpoint`. disengage distance to the surface.
* `Z-I, P`. z-piezo PI controler parameter.
* `Z-Initial I` z-piezo inital integral part.
* `Z-limit` Z-piezo control output limit, due to FPGA and Agilent 5500 control box, it cannot be larger than 10 V.
* `Deflection`, `X`, `Y - control` same as Z control. 
* `ImageToSample` this is used to correspond the sample location to pixel location
* `Clock` provides clock for each loop
* `Threshold` provides error threshold which traggers state transfer
* `scanning path file` provides the location of trajectory path
* `STOP` stops very thing.


### variables - all local variables
* `stageIndicator` shows the current state index
* `zControlMode` true for deflection control, false for z-axis control 
*  `x y z _pos` provide the location




