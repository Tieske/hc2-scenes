--[[
%% properties
%% globals
--]]

local historyName = "batteryHistory"  -- global name for this data
local deviceCount = "deviceCount"     -- global name for device count
local ignoreBelow = 50                -- any battery level below this will be ignored
local defaultLow = 70                 -- if no battery low available, assume this as lowest
local deviceOvershoot = 40
local d = os.date('*t') 
local dateNow = d.year .. "/" .. d.month .. "/" .. d.day

-- iterates over all devices. `fetch` is a function that gets an `id` and should return the
-- apropriate value for that device id, or `nil` if it does not belong in the collection
-- we are iterating.
local deviceIterator = function(fetch)
  local currentid = 0
  local lastfound = 0
  local endid = (tonumber(fibaro:getGlobalValue(deviceCount)) or 0) + deviceOvershoot
  return function()
      while currentid < endid do
        currentid = currentid + 1
        local value = fetch(currentid)
        if value ~= nil then 
          lastfound = currentid
          return currentid, value
        end
      end
      if lastfound > (endid - deviceOvershoot) then
        fibaro:setGlobal(deviceCount, tostring(lastfound))
      end
    end
end

-- iterates over all devices with a non-blank device name, returning: id, name
local deviceNameIterator = function()
  return deviceIterator(function(id)
      local value = fibaro:getName(id)
      if value ~= "" then return value end
    end)
end

-- iterates over all devices with a non-blank type name, returning: id, typename
local deviceTypeIterator = function()
  return deviceIterator(function(id)
      local value = fibaro:getType(id)
      if value ~= "" then return value end
    end)
end

-- iterates over all devices with the specified property, returning: id, propertyValue
-- empty string values and `nil` will not be returned by default.
-- If `blankAllowed == true` then empty string values will be returned.
local devicePropertyIterator = function(propertyName, blankAllowed)
  return deviceIterator(function(id)
      local value = fibaro:getValue(id, propertyName)
      if blankAllowed then return value end
      if value ~= "" then return value end
    end)
end

-- gets historic battery data
local function getHistory()
  
end


-- define tables to hold our data
-- indexed per device id, subtable containing
--   - everLow: lowest battery level ever seen (above 50%)
--   - deadSince: dead since; date

local history = {}  -- loaded history
local added = {}    -- devices added, not available in the history
local list = {}

-- check all devices for 'deadness' ;), try revive first
for id, dead in devicePropertyIterator('dead') do
  if dead >= "1" then
    fibaro:wakeUpDeadDevice(i) 
    fibaro:sleep(5000) --check again in 5 sec 
    dead = fibaro:getValue(i, 'dead');
    if dead >= "1" then
      -- really dead apparently, so record this
      list[id] = list[id] or {}
      dev.deadSince = (history[id] or {}).deadSince or dateNow  -- use new date, if no old date available
    end
  end
end

-- check battery status
for id, level in devicePropertyIterator('batteryLevel') do
  level = tonumber(level) or 0
  if level > ignoreBelow then
    list[id] = list[id] or {}
    if level < ((history[id] or {}).everLow or 999) then
      list[id].everLow = level
    else
      list[id].everLow = history[id].everLow
    end
    -- estimate percentage
    local low = (list[id].everLow == level and math.min(level,defaultLow)) or list[id].everLow
    list[id].batteryLevel = math.floor(100*(level-low)/(100-low) + 0.5)
  end
end


while i < TotalDevices do
  local status = fibaro:getValue(i, 'dead');
  
  if status == "1" then
    errors = errors + 1
    local desc = fibaro:getValue(i, "userDescription");
    local name = fibaro:getName(i);
    text = text ..  "\r "..name.."    ["..i.."] "..desc.." "
    fibaro:debug("Some problems with device "..name.." ["..i.."] "..desc.." Please check!"); 
  else end
  
  i = i + 1
end
text = text ..  "\r".. "Please check!"
if errors >= 1 then
 fibaro:call(2, "sendEmail", "Dead node report from Home Centre 2", text);
end  
