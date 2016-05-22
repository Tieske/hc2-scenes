--[[
%% properties
%% events
%% globals
DayNightStatus
--]]

-- switches on light at evening/night and off in the moring
-- NOTE: requires the `day-night-status` scene!

-- CONFIGURATION
-- =============

-- Global variable: this must be the same as the one from the `day-night-status` scene
-- and must be in the trigger block above !!!
local GlobalName = "DayNightStatus"

-- This list is only OFF during daylight and on all night
-- until morning
-- Provide a list with device IDs
local deep_night = { 
  236,   -- mainlight office
}   

-- This list is OFF during daylight and OFF during deepnight.
-- Provide a list with device IDs
local no_deep_night = { 
  236,   -- mainlight office
}   

-- on/off value to use for dimmers
local on_value = 99
local off_value = 0


-- ==========================
-- nothing to customize below
-- ==========================

-- turns all devices on or off based on the target value
-- @param list list of deviceIDs to switch
-- @param turnOff if `true` then all devices will be turned off, otherwise on. 
local function setValue(list, turnOff)
  for _, id in ipairs(list) do
    -- for on/off switches and dimmers
    fibaro:call(id, turnOff and "turnOff" or "turnOn") 
    
    -- for dimmers only
    fibaro:call(id, "setValue", turnOff and off_value or on_value)
  end
end

local DayNightStatus = fibaro:getGlobalValue(GlobalName)

if DayNightStatus == "Day" then
  setValue(deep_night, true)
  setValue(no_deep_night, true)
elseif DayNightStatus == "Night" then
  setValue(deep_night, false)
  setValue(no_deep_night, false)  
elseif DayNightStatus == "DeepNight" then
  setValue(deep_night, false)
  setValue(no_deep_night, true)  
else
  fibaro:debug("Error: unknown value for global variable '"..GlobalName.."'; "..tostring(DayNightStatus))
end
