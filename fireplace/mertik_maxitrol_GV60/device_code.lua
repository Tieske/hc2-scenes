
-- The pins can be used to set outputs, and then the pulse is used to
-- actually send a command
local pin1_id = 949   -- deviceid of device switching pin 1 on the interface, UP
local pin2_id = 941   -- deviceid of device switching pin 2 on the interface, IGNITE
local pin3_id = 951   -- deviceid of device switching pin 3 on the interface, DOWN
local pulse_id = 943  -- deviceid of device switching the actual signal on/off
local valve_runtime = 12  -- seconds for valve to run up/down fully

-- set the icon ID's of on and off icons
local onIcon = 1002
local offIcon = 1001


-- this delay is a delay after the signal has been set up, before the
-- actual pulse is send. This allows to overcome Zwave latencies.
-- So a 1 second delay, will set up the signal, wait 1 second for all the
-- relais to actually switch, and only then send the pulse
local pulse_delay = 2 --  in seconds

--- END OF CONFIGURATION SETTINGS ---
-- at the bottom enable code blocks for each button type of
-- your virtual device

--=======================================================================

local power_off  -- forward declaration of function

-- returns a value to indicate whether the fireplace is on or off. On may also
-- mean it is in/decreasing
-- if it cannot determine, it will send an "off" signal to reset (after a timeout)
local function is_started()
  local wait_step = 0.5  -- in seconds
  local wait_max = 120   -- in seconds
  local i = 0
  while true do
    -- read status
    local p = (tonumber(fibaro:getValue(pulse_id, "value")) > 0)
    local p1 = (tonumber(fibaro:getValue(pin1_id, "value")) > 0)
    local p2 = (tonumber(fibaro:getValue(pin2_id, "value")) > 0)
    local p3 = (tonumber(fibaro:getValue(pin3_id, "value")) > 0)

    if p1 or p2 or p3 then
      -- if any of the signal pins is set, something is in progress
      -- do nothing, just wait for it to complete
    else
      if p then
        -- fire place is on and stable
        return true
      else
        -- fire place is off
        return false
      end
    end

    -- ok, so we don't know... so wait and retry
    i = i + wait_step
    if i > wait_max then
      -- we have a timeout, let's be safe and reset the fireplace to OFF forcefully
      power_off(true)
      i = 0
    end
    fibaro:sleep(wait_step * 1000)
  end
end
  
-- sets the device icon
-- @param state if truthy device icon ON, otherwise device icon OFF
local function set_icon(state)
  local self_id = fibaro:getSelfId()
  local icon = state and onIcon or offIcon
  fibaro:call(self_id, "setProperty", "currentIcon", icon)
end

-- Ignite the fireplace.
-- will exit with nil+err if already in progress
-- will leave the 'pulse' on
local function ignite()
  if is_started() then
    -- already on, so exit
    return
  end
  
  -- pulse is off, so prepare signal
  fibaro:call(pin1_id, "turnOn")
  fibaro:call(pin2_id, "turnOff")
  fibaro:call(pin3_id, "turnOn")

  -- wait for completion of signal setup
  fibaro:sleep(pulse_delay * 1000)

  fibaro:call(pulse_id, "turnOn")
  
  -- wait for completion of signal
  fibaro:sleep(2000)   -- must wait 1 sec + some safety margin

  -- turn off the signal pins, pulse remains on
  fibaro:call(pin1_id, "turnOff")
  fibaro:call(pin2_id, "turnOff")
  fibaro:call(pin3_id, "turnOff")
  fibaro:call(pulse_id, "turnOn")
end

-- turn off the fireplace.
-- @param unconditional will bypass checks, and just turn it off forcefully
function power_off(unconditional)   -- no 'local' as it was forward declared above
  if not unconditional then
    if not is_started() then
      -- already off, so exit
      return
    end
  end

  -- pulse off, prepare signal
  fibaro:call(pulse_id, "turnOff")
  fibaro:call(pin1_id, "turnOn")
  fibaro:call(pin2_id, "turnOn")
  fibaro:call(pin3_id, "turnOn")

  -- wait for completion of signal setup
  fibaro:sleep(pulse_delay * 1000 * 3)  -- for safety we tripple the delay here!!!

  fibaro:call(pulse_id, "turnOn")
  
  -- wait for completion of signal
  fibaro:sleep(2000)   -- must wait 1 sec + some safety margin

  -- turn of the pulse off, signal pins remain on
  fibaro:call(pulse_id, "turnOff")
  fibaro:call(pin1_id, "turnOff")
  fibaro:call(pin2_id, "turnOff")
  fibaro:call(pin3_id, "turnOff")
end



--=======================================================================
-- button specific code below.
-- IMPORTANT: make sure only 1 is enabled!!
-- to enable, change the initial double dashes '--[[' into
-- triple dashes: '---[['

--=======================================================================
--[[     This code is for the ON button
ignite()
--]]

--=======================================================================
--[[     This code is for the OFF button
power_off(true)
--]]

--=======================================================================
--[[     This code is for the TOGGLE button, also to be the main button
if is_started() then
  power_off(true)
else
  ignite()
end
--]]

--=======================================================================
--[[     This code is for the MAIN LOOP
-- all we do here is set the icon according to the device state
local state = is_started()
set_icon(state)
--]]
