--[[
%% properties
%% globals
--]]

local historyName = "batteryHistory"  -- global name for this data
local wakeUpDelay = 5000              -- delay after reviving before check again, in ms
local ignoreBelow = 30                -- any battery level below this will be ignored
local defaultLow = 50                 -- if no battery low available, assume this as lowest
local d = os.date('*t') 
local dateNow = d.year .. "/" .. d.month .. "/" .. d.day

--------------------------------------------------------------------------------
-- External code imported; device iterator
--------------------------------------------------------------------------------

-- We just traverse all deviceIDs and fetch the device to see whether it exists.
-- There is no way to detect the total number of devices, so whenever we encounter
-- devices, we store the last one found in a global variable. Now to find new devices
-- beyond our last check we will "overshoot" the last id found by a fixed number.
-- If we found new devices in the "overshoot", the global variable will be updated.

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

-- check battery status
fibaro:debug("Checking battery levels...")
fibaro:log("Checking battery levels...")
fibaro:sleep(4000)  -- ensure log message remains visible in UI for a while
local cbattery = 0
for id, level in devicePropertyIterator('batteryLevel') do
  level = tonumber(level) or 0
  cbattery = cbattery + 1
  if level > ignoreBelow then
    list[id] = list[id] or {}
    if level < ((history[id] or {}).everLow or 999) then
      list[id].everLow = level
    else
      list[id].everLow = history[id].everLow
    end
    -- estimate percentage
    --local low = (list[id].everLow == level and math.min(level,defaultLow)) or list[id].everLow
    --list[id].batteryLevel = math.floor(100*(level-low)/(100-low) + 0.5)
    list[id].batteryLevel = level
  end
end
fibaro:debug("Check for battery levels completed; "..tostring(cbattery).." battery powered devices")

-- check all devices for 'deadness' ;), try revive first
fibaro:debug("Checking for dead devices...")
fibaro:log("Checking dead devices...")
local cdead, crevived = 0,0
for id, dead in devicePropertyIterator('dead') do
  if dead >= "1" then
    if (fibaro:getValue(id, "batteryLevel") or "") ~= "" then
      -- there is no use in trying waking up battery powered devices
      fibaro:debug("not waking up battery power device; "..tostring(fibaro:getName(id)).." ("..fibaro:getRoomName(fibaro:getRoomID(id))..")")
    else
      fibaro:debug("waking up "..tostring(fibaro:getName(id)).." ("..fibaro:getRoomName(fibaro:getRoomID(id))..")")
      fibaro:wakeUpDeadDevice(id) 
      fibaro:sleep(wakeUpDelay) --check again in x sec 
      fibaro:log("Checking dead devices...")
      dead = fibaro:getValue(id, 'dead');
      if dead >= "1" then
        -- really dead apparently, so record this
        local dev = list[id]
        if not dev then
          dev = {}
          list[id] = dev
        end
        dev.deadSince = (history[id] or {}).deadSince or dateNow  -- use new date, if no old date available
        cdead = cdead + 1
      else
        crevived = crevived + 1
      end
    end
  end
end
fibaro:debug("Check for dead devices completed; "..tostring(cdead).." dead devices ("..tostring(crevived).." revived)")

local newDead = {}
local longerDead = {}
local noLongerDead = {}
local batteryConst = {}
local batteryDown = {}
local batteryUp = {}
do
  -- check our newly created list (new and updates)
  for id, dev in pairs(list) do
    local details = tostring(id).." "..tostring(fibaro:getName(id)).." ("..fibaro:getRoomName(fibaro:getRoomID(id))..")"
    
    -- go check the dead ones and prepare to make a nice message
    if dev.deadSince then
      if (history[id] or {}).deadSince then
        -- was already dead
        table.insert(longerDead, "  "..details.." since "..dev.deadSince)
      else
        -- newly dead
        table.insert(newDead, "  "..details.." since "..dev.deadSince)
      end
    end
    
    -- report battery level
    if dev.batteryLevel then
      local bDetails = string.format("  %3i%% (was %3i%%, lowest %3i%%): ", dev.batteryLevel, oldLevel or 0, dev.everLow) .. details
      oldLevel = (history[id] or {}).batteryLevel
      if dev.batteryLevel == (oldLevel or dev.batteryLevel) then
        -- previous unknown level also goes here
        table.insert(batteryConst, bDetails)
      elseif dev.batteryLevel < oldLevel then
        table.insert(batteryDown, bDetails)
      else
        table.insert(batteryUp, bDetails)
      end
    end
  end
  
  -- check the history (for items removed)
  for id, dev in pairs(history) do
    local details = tostring(id).." "..tostring(fibaro:getName(id)).." ("..fibaro:getRoomName(fibaro:getRoomID(id))..")"

    -- go check the dead ones and prepare to make a nice message
    if dev.deadSince and not (list[id] or {}).deadSince then
      -- used to be dead, but no longer
      table.insert(noLongerDead, "  "..details.." since "..dev.deadSince)
    end
  end
  
end

-- returns table sorted by id (assuming 'details' string from above)
local function sortTable(tbl)
  table.sort(tbl, 
    function (a,b) 
      return (tonumber(a:match("(%d+)")) or -1) < (tonumber(b:match("(%d+)")) or -1)
    end)
  return tbl
end

-- returns formatted table, or ""
local function formatTable(tbl, title, post)
  if type(tbl) ~= "table" or #tbl == 0 then return "" end
  return title:upper().."\n"..string.rep("=", #title).."\n" .. table.concat(tbl, "\n")..(post or "")
end

-- email text and also post it to debug console
local function sendMessage(subject, text)
  fibaro:call(2, "sendEmail", subject, text);
  fibaro:debug("============ email sent ================")
  fibaro:debug("SUBJECT: "..subject)
  for line in string.gmatch(text.."\n", "(.-)\n") do
    fibaro:debug(line)
  end
  fibaro:debug("========== end email sent ==============")
end


local text = formatTable(sortTable(newDead), "Newly reported dead devices:", "\n\n") ..
             formatTable(sortTable(batteryDown), "Battery is down on:", "\n\n") ..
             formatTable(sortTable(batteryConst), "Battery is same on:", "\n\n") ..
             formatTable(sortTable(batteryUp), "Battery is up on:", "\n\n") ..
             formatTable(sortTable(noLongerDead), "Revived devices:", "\n\n") ..
             formatTable(sortTable(longerDead), "Remaining dead devices:", "\n\n")

sendMessage("Device report from Home Centre 2", text)
fibaro:log("Status email sent...")

