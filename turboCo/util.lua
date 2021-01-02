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

return {
  findPeripheral=findPeripheral,
  findPeripherals=findPeripherals,
}

