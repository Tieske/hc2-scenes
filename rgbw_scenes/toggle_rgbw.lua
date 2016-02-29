--[[
%% properties
72 value
%% globals
--]]


-- Uses a binary switch as a (toggle) remote control for an RGBW device.
-- Also takes any 'program' running into account
-- Connect a momentary switch to the remote device, but configure as toggle switch!
-- Scene code acts on the "On" command only.

local RemoteID = 72 -- device acting as remote control, MUST be same as trigger block above!!!
local DeviceID = 98 -- RGBW device to control

-- nothing to customize below

local startSource = fibaro:getSourceTrigger()
local remoteValue = tonumber(fibaro:getValue(RemoteID, "value"))
if  remoteValue > 0 or startSource["type"] == "other" then
  local deviceValue = tonumber(fibaro:getValue(DeviceID, "value"))
  local program = tonumber(fibaro:getValue(DeviceID, "currentProgramID"))
  if (deviceValue > 0 or program ~= 0) then
    fibaro:call(DeviceID, "turnOff")
  else
    fibaro:call(DeviceID, "turnOn")
  end
end


