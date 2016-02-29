-- Configuration:
-- when to run (once per day)
local runAtHour = 7
local runAtMinute = 0

-- End of configuration, nothing to customize below

if not alreadyRunning then
  alreadyRunning = true
  
  while true do
    -- Run check by activating the "Check Now" button above
    fibaro:call(fibaro:getSelfId(), "pressButton", "1")
    fibaro:sleep(2 * 60 * 1000)  -- sleep 2 minutes to prevent race condition
    -- wait for next iteration
    local time = os.date("*t")
    local sleep = (runAtHour * 60 + runAtMinute) - (time.hour * 60 + time.min)
    if sleep < 0 then sleep = sleep + 24 * 60 end
    fibaro:sleep(sleep * 60 * 1000)
  end
end
