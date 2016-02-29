--[[
%% properties
98 value
98 currentProgramID
%% globals
--]]

-- This scene code will restore the active program of an RGBW device, if one 
-- was running at the time of switching off the device. Instead of just switching on
-- to a white light.


-- customize this; RGB device ID and global to use to store state.
local deviceId = 98  -- MUST be the same as in the trigger block above!!!
local globalName = "RGBWsetting"..deviceId  -- make sure to manually create this global!!!

-- nothing to customize below



local startSource = fibaro:getSourceTrigger()
local property = startSource["type"] == "property" and startSource.propertyName
local value = tonumber(fibaro:getValue(deviceId, "value"))
local program = tonumber(fibaro:getValue(deviceId, "currentProgramID"))
local lastProgram = tonumber(fibaro:getGlobalValue(globalName))

if property == "currentProgramID" and program == 0 and value == 0 then
  --fibaro:debug("program id changed due to switching off, nothing to do")
elseif property == "currentProgramID" and program ~= lastProgram then
  --fibaro:debug("program id changed, now storing it")
  fibaro:setGlobal(globalName, program)
elseif property == "value" and value > 0 and program == 0 and lastProgram ~= 0 then
  --fibaro:debug("device on again, restoring program")
  fibaro:call(deviceId, "startProgram", lastProgram)
end

