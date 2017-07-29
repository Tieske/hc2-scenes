--[[
%% properties
953 value
954 value
955 value
956 value
957 value
958 value
%% events
%% globals
--]]

-- NOTE: these switches must all be in the trigger block above!!!!!
local switch_1h = 953  -- switch: left higher
local switch_1l = 954  -- switch: left lower
local switch_2h = 955
local switch_2l = 956
local switch_3h = 957
local switch_3l = 958

local heater_device_1 = 711  -- heaters left
local heater_device_2 = 849  -- heaters mid
local heater_device_3 = 850  -- heaters right

local key_device_map = {
  [switch_1h] = { device_id = heater_device_1, value = 33 },
  [switch_1l] = { device_id = heater_device_1, value = -34 },
  [switch_2h] = { device_id = heater_device_2, value = 33 },
  [switch_2l] = { device_id = heater_device_2, value = -34 },
  [switch_3h] = { device_id = heater_device_3, value = 33 },
  [switch_3l] = { device_id = heater_device_3, value = -34 },
}

-- get event details
local sourceID = tonumber(fibaro:getSourceTrigger().deviceID)
if not sourceID then
  -- triggered manually? do nothing, just exit
  return
else
  local target_device = key_device_map[sourceID].device_id
fibaro:debug("target device = "..tostring(target_device))
  local current_value = tonumber(fibaro:getValue(target_device, "ui.sliderValue.value"))
fibaro:debug("current value = "..tostring(current_value))
  local new_value = current_value + key_device_map[sourceID].value
  new_value = math.max(math.min(new_value, 100), 0)
fibaro:debug("new value = "..tostring(new_value))
  
  -- Set slider to calculated value
  fibaro:call(target_device, "setSlider", "1", new_value)
end
