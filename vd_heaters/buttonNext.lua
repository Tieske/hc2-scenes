local ThisDevice = fibaro:getSelfId()
local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))

-- calculate value
value = value + 33
if value > 100 then value = 0 end

-- Set slider to calculated value
fibaro:call(ThisDevice, "setSlider", "1", value)
