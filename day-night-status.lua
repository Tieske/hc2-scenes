--[[
%% autostart
%% properties
%% events
%% globals
--]]


-- This scene will set a Global variable based on sun being set or not.
-- When sun is set, value will be "Night", otherwise "Day"
-- If deep-night start and end times are provided, then between those
-- the status will be "DeepNight".

-- Example use of DeepNight; starting at "23:00", ending at "05:00".
-- Rule: Turn a light on at status "Night", turn it off at any other status.
-- Result: light goes on at sunset, off at 23:00, at 5:00 on again
-- and off again at sunrise.

-- NOTE: DeepNight will only override Night, never Day. Eg. if DeepNightStart
-- is set to "18:00" and the sun sets at "19:00", then at "19:00" status will
-- switch from Day to DeepNight.

-- ======================
-- USAGE / CUSTOMIZATIONS
-- ======================
-- provide a Name for the global variable. Create this variable 
-- manually in the variables panel. As a predefined variable, with values
-- "Day", "Night", and "DeepNight".
local GlobalName = "DayNightStatus"

-- set below values if you want to deviate from the standard sunrise/set times
local SunRiseDelta = 0        -- set Delta in minutes
local SunSetDelta = -SunRiseDelta   

-- set DeepNight start and end times (provide both or none)
local DeepNightStart = "0:00"   -- to disable DeepNight, set both to; nil
local DeepNightEnd = "5:00"     -- to disable DeepNight, set both to; nil



--------------------------------
-- Nothing to customize below --
--------------------------------


-- Return minutes since midnight from a string based time value. 
-- @param timeStr string containing time value, eg. "14:30"
-- @param delta delta in minutes to add to the time value
-- @return number; time + delta in minutes since midnight 
local function gettime(timeStr, delta)
  local hr, min = timeStr:match("^(.-)%:(.-)$")
  return hr * 60 + min + (delta or 0)
end

-- Function to actually check and update the global variable
function execute()

  local currentDate = os.date("*t")
  local time = currentDate.hour * 60 + currentDate.min  
  local sunset = gettime(fibaro:getValue(1, "sunsetHour"), SunSetDelta)
  local sunrise = gettime(fibaro:getValue(1, "sunriseHour"), SunRiseDelta)

  local SunIsSet = ((time < sunrise) or (time > sunset)) and "Night" or "Day"
  if SunIsSet == "Night" and DeepNightStart then
    local deepStart = gettime(DeepNightStart)
    local deepEnd = gettime(DeepNightEnd)
    if deepStart < deepEnd then
      -- eg; start = "1:00", end = "5:00"
      if time >= deepStart and time < deepEnd then SunIsSet = "DeepNight" end
    else
      -- eg; start = "23:00", end = "5:00"
      if time >= deepStart or time < deepEnd then SunIsSet = "DeepNight" end
    end
  end

  local SunIsSetStatus = fibaro:getGlobalValue(GlobalName)
  if not SunIsSetStatus then
    fibaro:debug("Global variable '"..GlobalName.."' not found, please create it in the variables panel!")
    return "error"
  end
  
  if SunIsSet ~= SunIsSetStatus then
    fibaro:debug("Updating '"..GlobalName.."' value: "..SunIsSetStatus.." -> "..SunIsSet)
    fibaro:setGlobal(GlobalName, SunIsSet)
  end
  return SunIsSet
end

fibaro:debug("Day/night value was checked to be "..execute())
if fibaro:countScenes() == 1 then
  -- We're the first, so go into an endless loop, checking every minute
  fibaro:debug("Starting day/night checking loop")
  while true do
    fibaro:sleep(60 * 1000)
    execute()
  end
end
