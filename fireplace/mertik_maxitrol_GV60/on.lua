--[[
%% properties
%% globals
--]]

local runHigh = 294  -- deviceid of device switching pin 1 on the interface
local runLow = 296   -- deviceid of device switching pin 3 on the interface
local valvetime = 12 -- time in seconds to run the valve from one end to the other

-- starts the fireplace, by running the starter sequence, and running the valve
-- completely open.
-- Be sure to take enough time before issueing the next command!
local function start()
  fibaro:call(runHigh, "turnOn")
  fibaro:call(runLow, "turnOn")

  fibaro:sleep(2000)

  fibaro:call(runHigh, "turnOff")
  fibaro:call(runLow, "turnOff")
end

