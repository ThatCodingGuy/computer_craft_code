-- Class representing a moving average where newer update cycles are given a
-- higher weight, and previous updates are exponentially given less.
local ExponentialMovingAverage = {}
ExponentialMovingAverage.__index = ExponentialMovingAverage 

-- Weight is the weight of new updates.
function ExponentialMovingAverage.new(weight)
    if weight <= 0 or weight >= 1 then
        error("ExponentialMovingAverage weight must be in range (0,1). Got " .. weight)
    end

    local self = setmetatable({}, ExponentialMovingAverage)
    self.average = nil
    self.weight = weight
end

function ExponentialMovingAverage.update(self, new_value)
    if self.average == nil then
        self.average = new_value
        return
    end
    local prev_average = self.average
    self.average = self.weight * new_value + (1 - self.weight) * prev_average
end

mod = {}
mod.ExponentialMovingAverage = ExponentialMovingAverage
return mod