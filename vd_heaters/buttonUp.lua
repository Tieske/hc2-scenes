local ThisDevice = fibaro:getSelfId()
local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))

-- calculate value
value = math.min(value + 33, 100)

-- Set slider to calculated value
fibaro:call(ThisDevice, "setSlider", "1", value)
