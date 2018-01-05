Setting home state and tracking user presence
=============================================

Based on user presence the state of the home is tracked.
Actually tracking the users themselves for presence is not included.

External controls can be used to automatically set the user status.

Creating the devices
====================

1. Created a number of global variables
  - "HomeState" with values "Home", "Away", "Sleep"
  - "AnyoneHome" with values "true", "false"
  - "SomeoneElse" with values: "Home", "Away"
  - for each user one with values: "Home", "Away", usually named by first name,
    e.g. "John" or "Mary"
2. create a new virtual device called "Home state" from the file
   `Home_State.vfib`. In the 'advanced' tab set the icons for each of the three
   buttons from the `home-xxxx.png` files.
3. create a new Lua scene, and copy the contents of the `state-update-scene.lua`
   file in there. Customize the top section such that:
   - the trigger block has all the global variable names of the users
   - the name list has all the global variable names of the users
4. create a new virtual device "Someone else", from the file `SomeoneElse.vfib`
   In the 'advanced' tab set the icons for each of the three
   buttons from the `others-xxxx.png` files. Note that "Toggle" should get the "home" icon.
5. for each of the users create a new virtual device by their name, from the file
   `SomeoneElse.vfib`.
   - In the 'advanced' tab set the icons for each of the three
     buttons from the `male-xxxx.png` or `female-xxxx.png` files. Note that
     "Toggle" should get the "home" icon.
   - In the code section update the first line, with the global variable name
     created for this user.

What it does
============

- When the last user is set to "away" the house moves to "Away" state
- When the first user returns to "Home" the house moves to "Home" state
- 2 generic global variables are now available, to be used in scenes:
   - `HomeState` (read-write)
   - `AnyoneHome` (read-only)


Advanced stuff
==============

- Based on user data, you can automatically set the Home/Away state for the
  users. This will then automatically trigger the proper actions.
  _NOTE: do not set their variable, but click the virtual device button!_
- Have a scene controller somewhere that puts the House in "Sleep" state or "Home" state
