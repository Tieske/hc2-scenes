---------------------------------
-- Customisation section       --
---------------------------------

-- list of 3 relays for switching lamellas
local relays = { 
  { 809, 812 },
  { 811, 813 },
  { 810, 814 },
} -- device ID's of lamella relays, or subtables if multiple devices

-- List of 4 Icon ID's (list may be empty)
local icons = {549, 550, 551, 552} --{ 4, 5, 6, 7 } -- off, 33%, 66%, 100%

---------------------------------
-- End of customisation        --
---------------------------------

local ThisDevice = fibaro:getSelfId()

-- retrieve value from slider
local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))
local target = 0

-- Calculate number of lamellas, and value to set
if value < 10 then 
  value = 0
  target = 0
elseif value <= 33 then 
  value = 33
  target = 1
elseif value <= 66 then
  value = 66
  target = 2
else
  value = 100
  target = 3
end

-- Set Icon
local icon = icons[target + 1]
if icon then
  fibaro:call(ThisDevice, "setProperty", "currentIcon", icon)
end

-- set actual relays
for n, st in ipairs(relays) do
  if type(st) ~= "table" then st = { st } end
  for _, id in ipairs(st) do
    local current = tonumber(fibaro:getValue(id, "value"))
    if n > target then
      if current ~= 0 then 
        -- only set the value if different, to minimize
        -- zwave network traffic, and have quicker
        -- device responses
        fibaro:call(id, "turnOff")
      end
    else
      if current == 0 then
        -- only set the value if different, to minimize
        -- zwave network traffic, and have quicker
        -- device responses
        fibaro:call(id, "turnOn")
      end
    end
  end
end

-- Set slider to calculated value
fibaro:call(ThisDevice, "setProperty", "ui.sliderValue.value", value)
fibaro:log("Output at "..value.." % ("..target.." lamellas)")
