Heater control
==============

based on heaters with 3 lamellas. Each having an individual relay.
Groups of heaters can also be switched.

Control is done through button (up/down) or using a slider (0-100%). When the
slider is used behaviour is: "off" < 10 < "33%" < 33 < "66%" < 66 < "100%" < 100.


Setting this device up
======================

1. create a virtual device
  1. id: "sliderValue"
  2. label: "Stand %"
2. add a slider first, then a line with 3 buttons
  1. ids; "Down", "Next", "Up"
  2. and labels: "buttonDown", "buttonNext", "buttonUp"
3. Each element gets the Lua code from the file with the same name. And the mainloop block gets the code from 'mainloop.lua'
4. import the 4 icons, note their ID's
5. for each element (device itself, slider, buttons) set the icon for 0%
6. mark button "buttonNext" as the "main" button

Now in the Lua code of the "sliderValue" box, customize the device ID's and the Icon ID's

Manual control
==============
1. use a fibaro RGBW device
2. connect switches for up and down to the inputs
3. use the scene in `manual_control.lua` to update the virtual devices