Setting this device up;

1. create a virtual device
  1. id: sliderValue
  2. label: "Stand %"
2. add a slider first, then a line with 3 buttons
  1. ids; Down, Next, Up
  2. and lables: buttonDown, buttonNext, buttonUp
3. Each element gets the Lua code from the file with the same name. And the mainloop block gets the code from mainloop.lua
4. import the 4 icons, note their ID's
5. for each element (device itself, slider, buttons) set the icon for 0%
6. mark button "buttonNext" as the "main" button

Now in the Lua code of the "sliderValue" box, customize the device ID's and the Icon ID's
