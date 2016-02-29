-- iterators to handle a specific device type, see examples at the bottom.


--------------------------------------------------------------------------------
-- External code imported; device iterator
--------------------------------------------------------------------------------

-- We just traverse all deviceIDs and fetch the device to see whether it exists.
-- There is no way to detect the total number of devices, so whenever we encounter
-- devices, we store the last one found in a global variable. Now to find new devices
-- beyond our last check we will "overshoot" the last id found by a fixed number.
-- If we find new devices in the "overshoot", the global variable will be updated.

-- prerequisite:
--    create a global variable with name "deviceCount"

local deviceCount = "deviceCount"     -- global name to store our device count
local deviceOvershoot = 40            -- by how many to overshoot to find new devices

-- iterates over all devices.
-- @param `fetch` is a function that gets an `id` and should return the
-- apropriate value for that device id, or `nil` if it does not belong in the collection
-- we are iterating.
-- @return When iterating it will return 2 values; deviceID (as number), and the value (the latter one
-- depends on what `fetch` returns)
local deviceIterator = function(fetch)
  local currentid = 0
  local lastfound = 0
  local oldDeviceCount = tonumber(fibaro:getGlobalValue(deviceCount)) or 0
  local endid = oldDeviceCount + deviceOvershoot
  return function()
      while currentid < endid do
        currentid = currentid + 1
        local value = fetch(currentid)
        if value ~= nil then 
          lastfound = currentid
          endid = math.max(endid, currentid + deviceOvershoot)
          return currentid, value
        end
      end
      if lastfound > oldDeviceCount then
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
-- @param propertyName the property to check on the device
-- @param blankAllowed (optional) If `true` then empty string values will be returned, 
-- otherwise blank responses will be handled as `nil`
local devicePropertyIterator = function(propertyName, blankAllowed)
  return deviceIterator(function(id)
      local value = fibaro:getValue(id, propertyName)
      if blankAllowed then return value end
      if value ~= "" then return value end
    end)
end
--------------------------------------------------------------------------------
-- End of external code imported; device iterator
--------------------------------------------------------------------------------


--- example code below;

-- print all devices with a name
for id, name in deviceNameIterator() do
  fibaro:debug(tostring(id).." - "..name)
end

--print all devices with a valid type
for id, devtype in deviceTypeIterator() do
  fibaro:debug(tostring(id).." - "..devtype)
end

-- print all devices with a property "batteryLevel"
for id, battery in devicePropertyIterator("batteryLevel") do
  fibaro:debug(tostring(id).." - "..battery)
end
