--[[
%% properties
%% weather
%% events
%% globals
Marieke
Remco
HomeState
SomeoneElse
--]]


-- List of names (global variables) to check for home/away state
-- NOTE: every name here MUST be in the trigger block above !!!!!!
local NameList = {
  "Marieke",
  "Remco",
  -- "SomeoneElse" is a generic other person; cleaner, babysitter, etc.
  "SomeoneElse",
}
local GlobalNameAnyoneHome = "AnyoneHome" -- value either "true" or "false"


----------- Nothing to customize below ------------

local HomeState = fibaro:getGlobalValue("HomeState")
local oldSomeoneHome = (fibaro:getGlobalValue(GlobalNameAnyoneHome) == "true")


-- Check all users for current state
local newSomeoneHome = false
for _, globalName in ipairs(NameList) do
  if fibaro:getGlobalValue(globalName) == "Home" then
    newSomeoneHome = true
    break
  end
end
if oldSomeoneHome ~= newSomeoneHome then
  fibaro:setGlobal(GlobalNameAnyoneHome, tostring(newSomeoneHome))
end


-- update home state
if HomeState == "Away" then
  if newSomeoneHome and not oldSomeoneHome then
    -- first one came home in while house was in 'Away' state
    fibaro:setGlobal("HomeState", "Home")
    fibaro:debug("first one came home: Away -> Home")
  else
    fibaro:debug("No change, state remains: Away")
  end

elseif HomeState == "Home" then
  if oldSomeoneHome and not newSomeoneHome then
    -- last one left while house was in 'Home' state
    fibaro:setGlobal("HomeState", "Away")
    fibaro:debug("last one left home: Home -> Away")
  else
    fibaro:debug("No change, state remains: Home")
  end

elseif HomeState == "Sleep" then
  if newSomeoneHome and not oldSomeoneHome then
    -- first one came home in while house was in 'Sleep' state
    fibaro:setGlobal("HomeState", "Home")
    fibaro:debug("first one came home: Sleep -> Home")

  elseif oldSomeoneHome and not newSomeoneHome then
    -- last one left while house was in 'Sleep' state
    fibaro:setGlobal("HomeState", "Away")
    fibaro:debug("last one left home: Sleep -> Away")

  else
    fibaro:debug("No change, state remains: Sleep")
  end

else
  -- shouldn't happen
  fibaro:debug("Something seems wrong, unknown state: " .. tostring(HomeState))
end
