Mertik Maxitrol fireplace control
=================================

Generic control
===============
See attached documents for pin controls available. The problematic part with
controling the fireplace is that the latency on the zwave network is quite often
too much. eg. igniting through pin 1 and 3 simultaneously, is not considered
"simultaneous enough" due to the latency between 1 and 3 switching.
To resolve this, we set it up though an extra switch that actually controls
the pulse. So we set up the 3 switches for the pins, wait a little for the
latency to pass. And then switch the pulse-relais, to pass the GND signal
to all output pins at once.

Schematics
==========
see included drawing of relais.
Components:
 2 - fibaro 2x 1.5 kw relay modules (modules A and B)
 2 - traditional relays, controlled on 230v AC (relais C and D)

One Fibaro module controls the pins 1 and 3 through relais A1 and A2. The
second Fibaro module controls pin 2 and the pulse through relais B1 and B2.
Because the B1 and B2 relais do not share the same input, we need
intermediate relais C and D.

An alternative solution would be to use 3 zwave modules (1 double relais, and
2 single relais).

Setting up the device
=====================

Create a device, add a row with 3 buttons, configured as follows:
1. named "On", enable Lua code
2. named "Toggle", enable Lua code, and set as "main" button
3. named "Off", enable Lua code

All 3 buttons and the main-loop code block get the same Lua code.
Configure the device ID's properly, and at the bottom, enable the
right code block for each button/main-loop.

Also set the Icon ID's for the ON/OFF status icons.
