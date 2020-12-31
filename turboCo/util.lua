
--[[
  Convenience function that returns all peripheral with the side
  and return both the peripheral and the side
]]
local function findPeripherals(peripheralType)
  local peripherals = {}
  for _,periphName in pairs(peripheral.getNames()) do
    local periphType = peripheral.getType(periphName)
    if periphType == peripheralType then
      local periph = peripheral.wrap(periphName)
      table.insert(peripherals, {periph=periph, name=periphName})
    end
  end
  return peripherals
end

--[[
  Find a peripheral and return both the peripheral and the side
  Writing this because the peripheral.find method doesn't give you back the side
]]
local function findPeripheral(peripheralType)
  local peripherals = findPeripherals(peripheralType)
  if #peripherals > 0 then
    return peripherals[1].periph, peripherals[1].name
  end
end

--[[
  Shamelessly stolen from stackoverflow.
  Splits a string into a table with the seperator given or whitespace by default
]]
local function split(inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--[[
  @return Does the table have the given value
]]
local function contains(tab, val)
  for _, value in pairs(tab) do
      if value == val then
          return true
      end
  end
  return false
end

return {
  findPeripheral=findPeripheral,
  findPeripherals=findPeripherals,
  split=split,
  contains=contains
}

