local pid = {}

-- retruns x within the limits of min/max
local function clamp(x, min, max)
  if x > max then
    return max
  elseif x < min then
    return min
  else
    return x
  end
end

local seconds = require("socket").gettime
local sleep = require("socket").sleep

-- all values of the PID controller
-- values with '_' at beginning are considered private and should not be changed.
pid = {
  kp = 0.5,
  ki = 2,
  kd = 1,
  input = nil,
  target = nil,
  output = nil,
  
  minout = -math.huge,
  maxout = math.huge,
  
  _lasttime = nil,
  _lastinput = nil,
  _Iterm = 0
}

-- Creates a new PID controller.
-- Passing table as an argument will make it used as an object base.
-- It allows for convinient saving and loading of adjusted PID controller.
function pid:new(save)
  assert(save == nil or type(save) == "table", "If save is specified then it has to be table.")
  
  save = save or {}
  setmetatable(save, self)
  self.__index = self
  return save
end

-- Exports calibration variables and targeted value.
function pid:save()
  return {kp = self.kp, ki = self.ki, kd = self.kd, target = self.target, minout = self.minout, maxout = self.maxout}
end

-- This is main method of PID controller.
-- After creation of controller you have to set 'target' value in controller table
-- then in loop you should regularly update 'input' value in controller table,
-- call c:compute() and set 'output' value to the execution system.
-- c.minout = 0
-- c.maxout = 100
-- while true do
--   c.input = getCurrentEnergyLevel()
--   c:compute()
--   reactorcontrol:setAllControlRods(100 - c.output) -- PID expects the increase of output value will cause increase of input
--   sleep(0.5)
-- end
-- You can limit output range by specifying 'minout' and 'maxout' values in controller table.
-- By passing 'true' to the 'compute' function you will cause controller to not to take any actions but only
-- refresh internal variables. It is most useful if PID controller was disconnected from the system.
function pid:compute(i, t, waspaused)
  self.input = i
  self.target = t or self.target  -- use existing target if omitted
  assert(self.input and self.target, "You have to sepecify current input and target before running compute()")
  
  -- reset values if PID was paused for prolonged period of time
  if waspaused or self._lasttime == nil or self._lastinput == nil then
    self._lasttime = seconds()
    self._lastinput = self.input
    self.output = self.output or clamp(0, self.minout, self.maxout)
    self._Iterm = self.output or 0
    return
  end
  
  local err = self.target - self.input
  local dtime = seconds() - self._lasttime
  
  if dtime == 0 then
    return
  end

  self._Iterm = self._Iterm + self.ki * err * dtime
  self._Iterm = clamp(self._Iterm, self.minout, self.maxout)
  
  local dinput = (self.input - self._lastinput) / dtime
  
  self.output = self.kp * err + self._Iterm - self.kd * dinput
  self.output = clamp(self.output, self.minout, self.maxout)
  
  self._lasttime = seconds()
  self._lastinput = self.input
  return self.output
end

--return pid

local mine = pid:new({minout = 0, maxout = 20})
local target = 100
local input = 10
local output = mine:compute(input, target)
local count = 0
while count < 2000 do
  print(count, "input: ", input, "output: ", output)
  if output ~= nil then 
    input = input + output/100 + math.random(-5, 5)
  end
  output = mine:compute(input, target)
  sleep(0.01)
  count = count + 1
  if count == 2000 and target == 100 then target = 130 count = 0 end 
end
