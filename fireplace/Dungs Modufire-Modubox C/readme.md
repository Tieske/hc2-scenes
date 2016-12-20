Configuring a fireplace

What's required;
 - connector cable for the fireplace
 - 24v operated relay, switching 230v
 - 2x Fibaro 2x1.5Kw relay modules
 
Wiring;
 - the fireplace has a main valve that is operated on 24V
 - connect a relay (24v in, switching 230v) to the valve
 - use 2 Fibaro 2x1.5Kw switches
 - label them A and B, and both having switches 1 and 2
 - output A1, and SWITCH INPUTS A2, B1 and B2 remain unconnected!
 - connect the outgoing 230v of the 24v relay to the SWITCH INPUT of A1
 - connect the fireplace 'common' as input to both A and B
 - connect the fireplace 'reset' to the output of A2
 - connect the fireplace 'up' to the output of B1
 - connect the fireplace 'down' to the output of B2

Configure devices;
 - configure A2, B1 and B2; auto-off parameter to 5 seconds
 - disable A1 in the user interface, as it should only switch on actual state changes
 - configure A1, as a toggle (bi-stable) switch
 - configure A1 state to follow the switch state (switch on -> output on, switch off -> output off)

Virtual device;
 - create a new virtual device
 - upload 2 icons (on and off)
 - add a bar with 3 buttons to the device
 - all of them get Lua code
 - 1st; called "On", set icon to the "OFF" icon
 - 2nd; called "Toggle", and marked as the "main" button
 - 3rd; called "Off", set icon to the "ON" icon
 - copy the code files into the respective code windows
 - update the id's at the top, for the devices and icons
 - save the device

