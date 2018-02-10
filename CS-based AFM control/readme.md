# Mu path pattern implenmentation on Agilent 5500 AFM


Please refer (http://ieeexplore.ieee.org/abstract/document/6315406/) as the theoretical analysis of this implementation. And you are welcome to contact: luoyuf@bu.edu 

The control algorithm contrains 6 states with the 1st one as the initialization, with 5 independent loops.

## The 6 states:

1. Initialization: In this state, users approach the tip to the sample with stepper motor using PicoView close loop control. Then release the control from PicoView to FPGA. The system writes parameters including the locations of mu-paths from desktop files to a host-to-FPGA FIFO (first in, first out) buffer. Turn on the close loop control of all the axes. The system performs the following operations,

Read the location of the first mu-path from the FIFO.
Set z-axis loop to position control mode.
Wait for |e_z(k)| reaches a settling criterion, then go to state 2.

2. xy-axis move: In this state, the system moves the tip to the target location.

Set x_ref ; y_ref to the beginning of the mu-path.
Wait for |e_x(k)|, |e_y(k)| reach a settling criterion. Then check the status of z-axis control. if z-axis is at position control mode, go to state 3, and if z-axis is at deflection control mode, go to state 4.

3. Tip engagement: In this state, the system drives the tip towards the sample surface. Here, we use a smaller K_i for z-piezo, which results in somewhat slower descent and less windup while the tip is out of contact.

Set z-axis loop to deflection control mode.
Wait for |e_z(k)| reaches a settling criterion, then go to state 4.

4. Measure: In this state, the system moves the tip following the trajectory of the mu-path. The x; y; z-axis and deflection measurements are logged into a FPGA-to-host FIFO buffer as the surface topography data. This will be described more fully in state, Sec. IV-A.

Update x_ref ; y_ref iteratively to follow the trajectory of the mu-path to the end. At the same time, write x; y; z-axis and deflection measurements to a FPGA-to-host FIFO.
Wait for |e_x(k)|, |e_y(k)| reach a settling criterion, then go to state 5.

5. Transition decision: The tip is at the end of the mu-path at this time. The location of the next mu-path is read from the FIFO. In order to accelerate the scanning process, the decision to lift the tip or not is made in this state. The time txy scan it takes to scan to the beginning of the next mu-path is compared to tzup + txy + tzdown. If the former is larger, then go to state 6; otherwise, go to
state 2.

6. Tip-disengage: In this state, the system withdraws the tip in the z-direction. A large K_i is used for z-piezo in order to save time.

Set z-axis loop to position control mode.
Wait for |e_z(k)| reaches a settling criterion, then go to state 2.


## The 5 loops:

1. x-piezo control loop  - control x-axis direction
2. y-piezo control loop  - control y-axis direction
3. z-piezo control loop  - control z-axis direction
4. state trigger control loop  - monitor and trigger state change
5. Data recording loop

## Data recording and reading
For all of this to work properly, data needs to packed into both `host-to-FPGA` and `fpga-to-host` in a specific format.

### host-to-FPGA
At the end of state 5, the next mu path location are read from host-to-FPGA FIFO with the following format:
[x position, y position, scan direction, scan length].

### FPGA-to-host
At state 4, data are recording to FPGA-to-host FIFO with the following format:
[x position, y position, z position, direction signal, state index].


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
* `mu path file path` provides the location of mu path
* `STOP` stops very thing.


### variables - all local


