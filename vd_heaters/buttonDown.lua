local ThisDevice = fibaro:getSelfId()
local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))

-- calculate value
value = math.max(value - 35, 0) -- 35, not 33, for rounding differences

-- Set slider to calculated value
fibaro:call(ThisDevice, "setSlider", "1", value)
