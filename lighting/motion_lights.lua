--[[
%% properties
567 value
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
  567,  -- sensor bathroom
}  

-- lights to dimm, can be both dimmers and on-off switches
local target_devices = { 
  885,   -- bathroom mainlight
}   
local target_off_only = {   -- these will be switched off automatically, but not on
  883,   -- bathrooom mirror light
}   
local target_on_only = {    -- these will be switched on automatically, but not off
--  240,   
}   

-- How long should the lights stay on. 
-- NOTE: this is counted after the sensor reports "NO_MOTION" so the sensor delay 
-- is added to the delay configured here.
local duration = 240  -- in seconds

-- on/off value to use for dimmers
local on_value = 99
local off_value = 0


-- ==========================
-- nothing to customize below
-- ==========================

-- let only one scene run;
if fibaro:countScenes() > 1 then fibaro:abort() end


-- get event details
local sourceID = tonumber(fibaro:getSourceTrigger().deviceID)
local sourceValue 
if sourceID then
  sourceValue = tonumber(fibaro:getValue(sourceID, "value"))
else
  -- triggered manually? use first sensor and report value as MOTION
  sourceID = source_devices[1]
  sourceValue = 1 
end

-- checks the list of sensors, returns `true` when there is motion on
-- any of the devices, `false` otherwise
local function motion()
  for _, id in ipairs(source_devices) do
    if tonumber(fibaro:getValue(id, "value")) ~= 0 then
      return true
    end
  end
  return false
end

-- sets a single target
local function setTarget(id, turnOff)
  -- for on/off switches and dimmers
  fibaro:call(id, turnOff and "turnOff" or "turnOn") 
  
  -- for dimmers only
  fibaro:call(id, "setValue", turnOff and off_value or on_value)
end

-- turns all devices on or off based on the target value
-- @param turnOff if `true` then all devices will be turned off, otherwise on. 
local function setValue(turnOff)
  for _, id in ipairs(target_devices) do
    setTarget(id, turnOff)
  end
  
  if turnOff then
    for _, id in ipairs(target_off_only) do
      setTarget(id, turnOff)
    end
  else
    for _, id in ipairs(target_on_only) do
      setTarget(id, turnOff)
    end
  end
end

setValue()  -- turn lights on

local time = 0
local checkDelay = 10 -- in seconds
while true do
  if motion() then
    -- still motion, nothing to do
    time = 0
  else
    -- no more motion
    time = time + checkDelay
    if time > duration then break end  -- we're done, so exit the loop
  end
  fibaro:sleep(checkDelay * 1000) -- sleep before checking again
end

setValue(true)  -- turn lights off

