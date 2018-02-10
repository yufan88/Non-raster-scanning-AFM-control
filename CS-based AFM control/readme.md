# Mu path pattern implenmentation on Agilent 5500 AFM


Please refer (http://ieeexplore.ieee.org/abstract/document/6315406/) as the theoretical analysis of this implementation. And you are welcome to contact: luoyuf@bu.edu 

The control algorithm contrains 6 states with the 1st one as the initialization, with 5 independent loops.

The 6 states are:

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


## FIFO data packing specifications
For all of this to work properly, data needs to packed into both `host-to-FPGA` and `fpga-to-host` in a specific format. One of the problems I was trying to solve with this is how do you determine what is a new setpoint and what is a trajectory? 
### host-to-FPGA
Both setpoint data (ie, move-entities) and measurement trajectory (ie, measurement entitities) come into the FPGA via the same fifo buffer. To distinguish which is which, I pack meta data with it, which is just a third number, which is always some integer. For new setpoint or movement data, this is always `j=0`. Then, when reading a new setpoint, we expect FIFO data to look like

```
[x_r(1), y_r(1), 0]
```

In my current setup, I expect *one* set that looks like that. The next set should correspond to a CS measurement. It will look like

```
[x_r(1), y_r(1), j, x_r(2), y(r), j, ... x_r(N), y_r(N), -1]
```

Notice that the index (meta data) j is the same, because j should be the index of the CS point we are currently measuring. The only exception to this is the end: when we reach the end of the current CS trajectory to follow, we expect `j=-1`, which is our trigger to stop measuring and transition from state 4 to state 5. 

If we timeout on reading the FIFO buffer and miss data, this whole scheme falls apart. That is why my vi is set to abort if any FIFO timout occurs.
### fpga-to-host
Currently, I am logging data for both states 1 and states 4, i.e., both moves and measurements. In reality, we could probably drop logging data for moves. The logging FIFO spec is similar, but we have more data to pass:

```
[x(1), y(1), e_z(1), z(1), u_z(1), j, x(2), y(2), e_z(2), z(2), u_z(2), j,...]

```

Again, we differentiate move from measurement data. For moves, we set j=0, while for measurements we set j equal to the CS index we got from `host-to-FPGA`. This, I believe, should ease post-processing on the host side. 

## Miscellanouse Concerns
### Instability detection
For all three axes, I check at each sample period if the control input exceeds some bound. If this is the case, I assume something has gone awry and abort. You could do something more sophiscticated I'm sure, but this works pretty well.

### FPGA exit
It is important to ensure the last values the FPGA writes to the DACs are all zero, because the DACs will hold onto their last value even after the FPGA vi exits. This is accomplished in the subvi `gracefull_return.vi`, which slowly returns all three controls towards zero, to avoid giving an uncontrolled large step input. I believe this vi should be hard coded, and not subject to user tweaking, which prevents accidently entering destructive values.

### XY nonzero initial condition.
On our piezo stage, the x and y sensor generally generate report a nonzero value for a zero control input. Therefore, I measure this initial offset before the main control loop starts, and subtract it off of all subsequent ADC measurements. 

### Functionality separation
I have tried to separate decision making from other logic in the state machine. For example, data logging, and FIFO buffer reading, and xy-axis PI control happen in more than one state. Thus, the code to do these tasks is moved outside the state machine, which prevents having code that does the same thing in more than one state. This has a couple of advantages:
1. You only have to update the code in one place.
2. This should decrease FPGA fabric consumption.

This could also be done for the z-axis PI control, but I haven't gotten around to it yet. 



## Host VI and Front Panel Controls

### Tab 1
These are the most commanly used settings.
1. `init-Zup`. Increase this to disengage the surface.
* `trigger-0`. Hitting this transitions us from state 0 to state 1.
* `z-UP`. This is the amount, in volts, to step the z-axis up in state 5. 
* `numEntities`. The total number of CS entitites we intend to visit. It would be better to read this value off of some meta data in a header of the data-in.csv file
* `ki-xy`. This is the control gain for the x and y PI controller transfer function, which looks like ki/(z -1). 
* `TsTicks` This sets the sample frequency. 1600 ticks at 40Mhz is 25khz.
* `TOL`. This is the tolerance to detect sample engagement in state 2.
* `setpoint` This is the z-axis setpoint, ie error-signal=(setpoint - deflection_signal)
* `z-u-max`. The maximum allowable z-axis input before we conclude instability and abort the entire thing. 
* `ramp-rate` How fast we approach the sample in state 2. This is in volts per sample period and MUST be negative (for our system). -5e-6 is really slow, -5e-5 is fast in human time. It would be good to make this as fast as possible. 

### Tab 2: xy-axis tweaks
1. `xy error threshold`. This determines how close to the setoint we must be to consider the x and y axes to have settled in state 1. 
* `xy-settled samples`. How many samples the x or y axis must be inside of the error threshold before we declare settling.

### Tab 3: z-axis tweaks
1. `z-error threshold`,This determines how close to the setoint we must be to consider the z axis to have settled in 3.
* `z-settled samples`. How many samples the z  axis must be inside of the error threshold before we declare settling. 
`z-up-N` How many samples do we wait for in state 5.



