--[[
%% properties
549 value
554 value
577 value
%% events
%% globals
--]]

-- Turns lights on/off based on a set of motion sensors
-- Supports multiple motion sensors and multiple lights, both
-- dimmers and on/off switches.
-- The dimmer on-levels can be configured per time-slot, as well as an
-- "always-on" timeslot can be configured
-- Each device can do on/off, on-only, or off-only.

-- CONFIGURATION
-- =============
-- motion sensors; must all be listed above in trigger block!
local source_devices = { 
  549,  -- sensor left
  554,  -- sensor right
  577,  -- sensor staircase
}  

-- lights to dim, can be both dimmers and on-off switches
local target_devices = { 
  52,   -- bathroom mainlight
}   
local target_off_only = {   -- these will be switched off automatically, but not on
  --883,   -- bathrooom mirror light
}   
local target_on_only = {    -- these will be switched on automatically, but not off
--  240,   
}   

-- on value to use per time slot (from a specific time)
-- it MUST have at least 1 value
local on_values  = {
  ["07:00"] = 99,
  --["21:00"] = 5,     -- from 21:00 to 07:00 set dimmers to 5%
}

-- always on time frame. Between the given times
-- the light will remain on (must still be triggered by motion to switch on!)
local always_on_start --= "20:00"  --undefined means no always-on slot
local always_on_end   --= "07:00"

-- How long should the lights stay on. 
-- NOTE: this is counted after the sensor reports "NO_MOTION" so the sensor delay 
-- is added to the delay configured here.
local duration  = 240  -- in seconds

-- ==========================
-- nothing to customize below
-- ==========================

-- Return minutes since midnight from a string based time value. 
-- @param timeStr (optional) string containing time value, eg. "14:30", defaults to current time
-- @param delta (optional) delta in minutes to add to the time value, defaults to 0
-- @return number; time + delta in minutes since midnight
local function gettime(timeStr)
  local hr, min
  if not timeStr then
    -- no time given, so get current time
    local currentDate = os.date("*t")
    hr  = currentDate.hour
    min = currentDate.min
  else
    hr, min = timeStr:match("^(.-)%:(.-)$")
  end
  return hr * 60 + min
end


-- Checks the list of sensors for motion.
-- Within the start and end time, always motion will be reported.
-- @param source_devices list with device id's of sensors to check
-- @param AO_start (optional) always-on start time (minutes since midnight)
-- @param AO_end (optional) always-on end time (minutes since midnight)
-- returns "always" if within time frame, `true` when there is motion on any of
-- the devices, `false` otherwise
local function motion(source_devices, AO_start, AO_end)
  if AO_start and AO_end then
    local now = gettime()
    if AO_start < AO_end then
      -- timeslot during the day
      if now >= AO_start and now < AO_end then
        return "always"
      end
    else
      --timeslot across midnight
      if now >= AO_start or now < AO_end then
        return "always"
      end
    end
  end

  -- check the status of our sensors
  for _, id in ipairs(source_devices) do
    if tonumber(fibaro:getValue(id, "value")) ~= 0 then
      return true
    end
  end
  return false
end

-- Sets a single target.
-- @param id the device id to set, must be either an On/Off relay, or a dimmer
-- @param value the value to which to set the device (0-100), for relays 0 = off, 1-100 = on
local function setTarget(id, value)
  -- for on/off switches and dimmers
  fibaro:call(id, (value == 0) and "turnOff" or "turnOn") 
  
  -- for dimmers only
  fibaro:call(id, "setValue", value)
end

-- turns all devices on or off based on the target value
-- @param turnOff if `true` then all devices will be turned off, otherwise on. 
local function setValue(value, target_devices, target_off_only, target_on_only)
  fibaro:debug("setting targets to: "..tostring(value))

  for _, id in ipairs(target_devices) do
    setTarget(id, value)
  end
  
  if value == 0 then
    for _, id in ipairs(target_off_only) do
      setTarget(id, value)
    end
  else
    for _, id in ipairs(target_on_only) do
      setTarget(id, value)
    end
  end
end

-- gets the current value to set from the time slots
-- @param times values indexed by starting time
-- @param time (optional) the time for which to get the value, defaults to now
local function getValueToSet(times, time)
  time = time or gettime()
  local slotStart, slotValue
  local lastStart, lastValue
  for t, v in pairs(times) do
    t = gettime(t)
    if t > (lastStart or -1) then
      lastStart = t
      lastValue = v
    end
    if (t <= time) and (t > (slotStart or -1)) then
      slotValue = v
      slotStart = t
    end
  end
  return slotValue or lastValue
end


-- prepare data and settings
always_on_start = gettime(always_on_start)
always_on_end = gettime(always_on_end)
local checkDelay = 10 -- in seconds
local durationCount = 0
local last_set

-- before we check for the number of instances running of this scene,
-- we must turn them on to make sure we react promptly on motion events.
-- We DO NOT turn off, that is reserved for the loop below, after the
-- configured delay expires
local m = motion(source_devices, always_on_start, always_on_end)
if m ~= false then
  last_set = getValueToSet(on_values)
  setValue(last_set, target_devices, target_off_only, target_on_only)
  fibaro:debug("new invocation, set value "..tostring(last_set))
end

-- now verify that no other scene is running, we only want 1 scene to enter
-- the loop below
if fibaro:countScenes() > 1 then
  fibaro:abort()
end

-- enter an endless loop to check for value updates, and to turn off eventually
while true do
  fibaro:debug("waiting for next check "..tostring(durationCount).."/"..tostring(duration))
  fibaro:sleep(checkDelay * 1000) -- sleep before checking again
  durationCount = durationCount + checkDelay
  
  fibaro:debug("checking state now")
  m = motion(source_devices, always_on_start, always_on_end)
  local target_value
  if m then
    -- either true (motion) or in the "always-on" timeframe
    target_value = getValueToSet(on_values)
    durationCount = 0
  elseif durationCount < duration then
    -- no more motion, but the "on-duration" hasn't expired yet
    target_value = getValueToSet(on_values)
  else
    -- no motion, and the duration has expired, so we can finish up now
    fibaro:debug("no more motion, exiting scene")
    break -- exit loop
  end
  
  -- only update devices, if the value to set differs from the last one set
  if target_value ~= last_set then
    fibaro:debug("target value changed from "..tostring(last_set).." to "..tostring(target_value))
    last_set = target_value
    setValue(target_value, target_devices, target_off_only, target_on_only)
  end
end

-- we're done
setValue(0, target_devices, target_off_only, target_on_only) -- turn off
