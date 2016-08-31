
local oldvalue = value  -- "value" is a global to track status
if not oldvalue then value = 0 end -- not started, to be sure switch off

if not value = oldvalue then
  -- enable debug messages
  local debug = true

  -- list of 3 relays for switching lamellas
  local relays = { 
    { 809, 812 },
    { 811, 813 },
    { 810, 814 },
  } -- device ID's of lamella relays, or subtables if multiple devices

  -- List of 4 Icon ID's (list may be empty)
  local icons = {} --{ 4, 5, 6, 7 } -- off, 33%, 66%, 100%




  -- nothing to customize below

  local print = function(...) 
    if debug then 
      local l = {...}
      for k,v in ipairs(l) do l[k] = tostring(v) end
      fibaro:debug(table.concat(l," "))
    end
  end

  local ThisDevice = fibaro:getSelfId()
  local value = tonumber(fibaro:getValue(ThisDevice, "ui.sliderValue.value"))
  local target = 0

  -- Calculate number of lamellas, and value to set
  print("Input value:", value)
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
  print("Input results:", value, "Lamellas:", target)

  -- Set Icon
  local icon = icons[target + 1]
  if icon then
    fibaro:call(ThisDevice, "setProperty", "currentIcon", icon)
  end

  -- Set slider to calculated value
  fibaro:call(ThisDevice, "setProperty", "ui.sliderValue.value", value)
  fibaro:log("Output at "..value.." %")

  -- set actual relays
  local output
  for n, st in ipairs(relays) do
    if type(st) ~= "table" then st = { st } end
    for i, id in ipairs(st) do
      if n > target then
        print("Setting:",id, "Off")
        fibaro:call(id, "turnOff")
      else
        print("Setting:",id, "On")
        fibaro:call(id, "turnOn")
      end
    end
  end
