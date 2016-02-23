-- Two functions for encoding and decoding string data into a global to
-- ensure persisting data over time.


-- apparently this is not necessary, as the Lua code can already store any string... duh...


-- Decodes the value of a gloabl into an arbitrary string value.
-- @param globalName The name of the global containing the data
-- @return decoded string value, or an empty string on a decoding error
local function getString(globalName)
  local data = fibaro:getGlobalValue(globalName)
  local t = {}
  for c in string.gmatch(data, "%d%d%d") do
    local c = tonumber(c)
    if (not c) or (c < 0 or c > 255) then
      fibaro:debug("ERROR: Failed decoding string value of global '"..globalName.."'")
      return ""
    end
    table.insert(t, string.char(tonumber(c)))
  end
  return table.concat(t)
end

-- Encodes an arbitrary string value and stores it into a global.
-- @param globalName The name of the global to store the data in
-- @return nothing
local function setString(globalName, data)
  local t = {}
  for n = 1, #data do
    t[n] = string.format("%03i", string.byte(data, n))
  end
  fibaro:setGlobal(globalName, table.concat(t))
end
