-- PWM based heating control
-- =========================
-- Pulse Width Modulation algorithm. It uses an on/off heating system and varies the time
-- the heating is on, based on an input percentage and system parameters.

-- enable some debug output for testing
-- set to true to enable
local debugmode = false

-- the device id of the heating relay.
-- Closing the relay starts the heating system, opening it stops heating.
local relayId = 141

-- What time is necessary after starting the heating system (by closing the relay) to actually feed heat into the room.
-- (time to open the valve, start the boiler, pump the water into the room, etc.)
-- For electrical heating this is 0 for example, for water/boiler based underfloor heating, this might be a few minutes.
local startupTime = 3  -- in minutes

-- Minimum duration of heating the room. This excludes the startupTime.
-- So a startupTime of 2 minutes, and a minimum heating time of 4 minutes, would lead to minimum cycle time
-- of 6 minutes between opening and closing the relay.
-- NOTE: this will not be honored if an extremely low load is set (eg. 0-5%)
local minHeatingTime = 3  -- in minutes

-- How many heating cycles to use per hour. This should be set based on how quickly the room temperature 
-- responds and the startupTime. 
-- Eg. electrical heating is quick, and has no startupTime, so a higher number of cycles is appropriate
-- Water based underfloor heating has a high startupTime, and is slow responding, so a lower number of cycles 
-- should be set
-- Examples for the Secure SRT321 thermostat manual;
-- For Gas boilers set to 6 cycles per hour.
-- For Oil boilers set to 3 cycles per hour.
-- For Electric heating set to 12 cycles per hour.
-- NOTE: This will not be honored if startupTime and minHeatingTime require a lower number of cycles
-- per hour.
local hourlyCycles = 3  -- in cycles per hour


-- NOTHING TO CUSTOMIZE BELOW
-- ==========================


local debug = function(...)
  if debugmode then
    fibaro:debug(table.concat({...}, "\t"))
  end
end

-- check inputs
if startupTime == 0 then startupTime = 0.001 end -- prevent div by zero errors
if minHeatingTime == 0 then minHeatingTime = 0.001 end -- prevent div by zero errors
assert(startupTime >0 and startupTime < 30, "startupTime must be > 0 and < 30")
assert(minHeatingTime >0 and minHeatingTime < 30, "minHeatingTime must be >0 and < 30")
assert(hourlyCycles>0 and math.floor(hourlyCycles) == hourlyCycles, "hourlyCycles must be an integer value > 0")

-- calculate cycle time of one closing/opening relay cycle
-- @param ld percentage of heating time (0-100)
-- @return 3 values; 
--   1) number of cycles per hour
--   2) cycle fire duration (incl. the startup time, so relay closing time)
--   3) cycle idle duration (relay open time)
local function cycletime(ld)
  assert(ld and (ld>=0 and ld<=100), "load percentage must be a number from 0 to 100")
  if ld == 0 then
    return 1, 0, 60
  elseif ld == 100 then
    return 1, 60, 0
  end
  ld = ld / 100
  
  -- what is the maximum number of cycles, based on minimum heating time
  local cycles = math.floor((ld*60)/minHeatingTime)
  if cycles < 1 then cycles = 1 end
  
  -- what is the maximum number of cycles based on startupTime
  local stCycles = math.floor((1-ld)*60/startupTime)
  if stCycles < 1 then stCycles = 1 end
  
  -- pick the smallest one
  cycles = math.min(cycles, stCycles, hourlyCycles)
  
  -- calculate durations per cycle
  local fireTime = (60*ld)/cycles + startupTime
  if fireTime > 60 then fireTime = 60 end
  local idleTime = (60*(1-ld))/cycles - startupTime
  if idleTime < 0 then idleTime = 0 end
  
  return cycles, fireTime, idleTime
end

if not alreadyStarted then
  alreadyStarted = true   -- only run this once
  
  -- create a debug dump based on current variables;
  fibaro:debug("Current settings:")
  fibaro:debug("-   startupTime   : "..startupTime.." minutes (before heat reaches the room)")
  fibaro:debug("-   minHeatingTime: "..minHeatingTime.." minutes (minimum time for heating the room)")
  fibaro:debug("-   hourlyCycles  : "..hourlyCycles.." (maximum number of cycles per hour)")
  fibaro:debug("Result of current settings at specified loads:")
  for n = 0, 100 do
    local cycles, fireTime, idleTime = cycletime(n)
    local totalTime = idleTime + fireTime
    fibaro:debug(("%3d%%   =>  %d cycles of %3.1f minutes, of which the heating is on for %3.1f minutes"):format(n, cycles, totalTime, fireTime))
  end

end

-- global variable, indicating when the current relay state was set
lastSet = lastSet or os.time()
-- get current state of relay
local relayClosed = (tonumber(fibaro:getValue(relayId, "value")) > 0)
-- get currently set load percentage from the UI
local ld = tonumber(fibaro:getValue(fibaro:getSelfId(), "ui.sliderLoad.value"))


local now = os.time()
local _, fireTime, idleTime = cycletime(ld)
fireTime = fireTime * 60
idleTime = idleTime * 60

-- determine target relay state
local target
local nexttime
if relayClosed then
  -- we are currently heating
  if now < lastSet + fireTime then
    -- heating period is not over yet, so nothing to do basically
    nexttime = lastSet + fireTime - now
    debug("- waiting for heating period to end in "..nexttime.." seconds")
  else
    -- heating period is over, so change to idle
    debug("- heating period over, so switching relay off (open)")
    lastSet = now
    if idleTime == 0 then
      -- there is no idle time, so to prevent unnecessary flipping the relay we're not 
      -- setting the relay in this case
      debug("- exception; idle time duration == 0, so not switching relay off")
    else
      target = "turnOff"
    end
  end
else
  -- we're in idle state currently
  if now < lastSet + idleTime then
    -- idle period is not over yet, so nothing to do basically
    nexttime = lastSet + idleTime - now
    debug("- waiting for idle period to end in "..nexttime.." seconds")
  else
    -- idle period is over, so change to heating
    debug("- idle period over, so switching relay on (closing)")
    lastSet = now
    if fireTime == 0 then
      -- there is no fire time, so to prevent unnecessary flipping the relay we're not 
      -- setting the relay in this case
      debug("- exception; heating time duration == 0, so not switching relay on")
    else
      target = "turnOn"
    end
  end
end

-- actually set the relay state
if target then
  debug("- setting relay: "..target)
  fibaro:call(relayId, target)
end

-- Set timer properly
nexttime = nexttime or 1
if nexttime > 60 then nexttime = 60 end  -- at least once per minute
fibaro:sleep(nexttime * 1000)
