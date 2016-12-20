local icon_off_id = 865
local icon_on_id = 866
local device_up_id = 905
local device_down_id = 904
local device_reset_id = 902
local device_state_id = 903
local self_id = fibaro:getSelfId()

-- check state of actors
local state  = tonumber(fibaro:getValue(device_state_id, "value"))
local state1 = tonumber(fibaro:getValue(device_up_id, "value"))
local state2 = tonumber(fibaro:getValue(device_down_id, "value"))
local state3 = tonumber(fibaro:getValue(device_reset_id, "value"))

-- we only execute a command when nothing is in progress, which means
-- that all switches must be OFF, and current state is OFF
if state1+state2+state3 == 0 and state == 0 then
  -- must enable up & down to switch state of the fireplace
  fibaro:call(device_up_id, "turnOn")
  fibaro:call(device_down_id, "turnOn")
  -- NOTE: the device are configured to AUTO_OFF in 5 seconds!!!
end
