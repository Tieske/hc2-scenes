local ThisDevice = fibaro:getSelfId()

-- go in endless loop to force updates in case one is missed due to some
-- technical reason.

while true do
  local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))
  -- set to value -1; forces an update but has no real effect
  fibaro:call(ThisDevice, "setSlider", "1", value - 1)
  
  fibaro:sleep(1 * 60 * 1000) -- 1 minute
end