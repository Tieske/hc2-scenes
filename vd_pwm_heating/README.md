PWM based heating control
=========================

Pulse Width Modulation algorithm. It uses an on/off heating system and varies the time
the heating is on, based on an input percentage and system parameters.
NOTE: this is NOT a thermostat!

Creating the device
===================

1. create a new virtual device
2. add 1 "slider" ui element
3. switch the slider from "string" to "Lua code"
4. set "label" to "Load (%)"
5. set "ID" to "sliderLoad"
6. set icons for both the device itself as well as the slider control
7. copy the Lua code into the main loop
8. customize the settings at the top of the Lua code

