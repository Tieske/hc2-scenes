-- mainloop does nothing but checking/correcting the icon

local icon_off_id = 865
local icon_on_id = 866
local device_up_id = 905
local device_down_id = 904
local device_reset_id = 902
local device_state_id = 903
local self_id = fibaro:getSelfId()

local current_state = tonumber(fibaro:getValue(device_state_id, "value"))
if current_state == 0 then
  fibaro:call(self_id, "setProperty", "currentIcon", icon_off_id)
else
  fibaro:call(self_id, "setProperty", "currentIcon", icon_on_id)
end  
