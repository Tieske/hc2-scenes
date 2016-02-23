--[[
%% properties
%% globals
--]]

local i = 1;
local TotalDevices = 40 + 1;
local errors = 0
local text = 'Some problems with device ;'

local historyName = "batteryHistory"  -- global name for this data
local deviceCount = "deviceCount"     -- global name for device count
local deviceOvershoot = 40

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

-- gets historic data
local function getHistory()
  
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
