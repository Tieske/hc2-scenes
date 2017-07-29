--[[
%% properties
549 value
554 value
577 value
%% events
%% globals
--]]

-- turns lights on/off based on a set of motion sensors
-- supports multiple motion sensors and multiple light, both
-- dimmers and on/off switches.
-- Each device can do on/off, on-only, or off-only.

-- CONFIGURATION
-- =============
-- motion sensors; must all be listed above in trigger block!
local source_devices = { 
  549,  -- sensor links 
  554,  -- sensor rechts
  577,  -- sensor trapgat boven
}  

-- lights to dimm, can be both dimmers and on-off switches
local target_devices = { 
  52,   -- bathroom mainlight
}   
local target_off_only = {   -- these will be switched off automatically, but not on
  --883,   -- bathrooom mirror light
}   
local target_on_only = {    -- these will be switched on automatically, but not off
--  240,   
}   

-- How long should the lights stay on. 
-- NOTE: this is counted after the sensor reports "NO_MOTION" so the sensor delay 
-- is added to the delay configured here.
local duration  = 240  -- in seconds

-- on/off value to use (for relays 0 = off, else on)
local on_value  = 99
local off_value = 0

-- always on time frame (must still be triggered by motion!)
local always_on_start = "20:00"  --undefined means no always-on slot
local always_on_end   = "07:00"
local always_on_value = 5  -- dimmer value to use in the always on period

-- ==========================
-- nothing to customize below
-- ==========================

fibaro:debug("scene triggered")

-- get event details, what is that got this scene started?
local sourceID = tonumber(fibaro:getSourceTrigger().deviceID)
local sourceValue 
if sourceID then
  sourceValue = tonumber(fibaro:getValue(sourceID, "value"))
  fibaro:debug("triggered by "..tostring(sourceID).." value "..tostring(sourceValue))
else
  -- triggered manually? use first sensor and report value as MOTION
  fibaro:debug("triggered by no device? manually?")
  sourceID = source_devices[1]
  sourceValue = 1
end

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
    AO_start = gettime(AO_start)
    AO_end = gettime(AO_end)
    local now = gettime()
    if AO_start < AO_end then
      -- timeslot during the day
      if now >= AO_start and now < AO_end then
        fibaro:debug("motion: always on")
        return "always"
      end
    else
      --timeslot across midnight
      if now >= AO_start or now < AO_end then
        fibaro:debug("motion: always on")
        return "always"
      end
    end
  end

  -- check the status of our sensors
  for _, id in ipairs(source_devices) do
    if tonumber(fibaro:getValue(id, "value")) ~= 0 then
      fibaro:debug("motion: device "..tostring(id))
      return true
    end
  end
  fibaro:debug("motion: none")
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


local time = 0
local checkDelay = 10 -- in seconds
local last_set
while true do
  fibaro:debug("checking state now")
  local m = motion(source_devices, always_on_start, always_on_end)
  local target_value
  if m == "always" then
    target_value = always_on_value
    time = 0
  elseif m then -- still motion
    target_value = on_value
    time = 0
  elseif time > duration then  -- no more motion and our delay expired
    target_value = off_value
  else  -- no more motion, but still waiting for delay to expire
    target_value = last_set
  end
  if target_value ~= last_set then
    fibaro:debug("target value changed from "..tostring(last_set).." to "..tostring(target_value))
    last_set = target_value
    setValue(target_value, target_devices, target_off_only, target_on_only)
  end
  -- let only one scene run
  -- we only check after setting the initial value, to make sure we respond
  -- immediately on a motion event
  if fibaro:countScenes() > 1 then
    fibaro:debug("exiting, already running")
    fibaro:abort()
  end

  if time > duration then
    fibaro:debug("no more motion, exiting scene")
    break
  end  -- we're done, so exit the loop
  fibaro:debug("waiting for next check "..tostring(time).."/"..tostring(duration))
  fibaro:sleep(checkDelay * 1000) -- sleep before checking again
  time = time + checkDelay
end

setValue(0, target_devices, target_off_only, target_on_only)   -- turn lights off

