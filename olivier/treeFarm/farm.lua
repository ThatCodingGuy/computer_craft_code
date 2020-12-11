local WOOD_SLOT = 1
local FUEL_SLOT = 16
local SAPLING_SLOT = 15
local GENERATED_FUEL_SLOT = 14

local WOOD_NAME = "minecraft:log"
local SAPLING_NAME = "minecraft:sapling"
local FUEL_NAME = "minecraft:coal"

local NUM_TREES = 6
local DISTANCE_TO_TREE = 3
local DISTANCE_TO_ROW = 4
local DISTANCE_TO_SMELTER = 10
local NUM_SLOTS = 16

local MAX_FUEL_CARRIED = 30
local MAX_SAPLINGS_CARRIED = 30
local COAL_PERCENTAGE = 80

local SLEEP_TIME = 180 -- 3 mins

function refuelIfNeeded()
  if turtle.getFuelLevel() < 500 then
    turtle.select(FUEL_SLOT)
    if turtle.getItemCount() < 5 then
      print("Ran out of fuel. plz fix.")
    else
      turtle.refuel(5)
    end
    turtle.select(WOOD_SLOT)
  end
end

function plantSapling()
  for i=1,NUM_SLOTS do
    local itemDetail = turtle.getItemDetail(i)
    if itemDetail ~= nil and SAPLING_NAME == itemDetail.name then
      turtle.select(i)
      turtle.place()
      turtle.select(WOOD_SLOT)
      return
    end
  end
  print("Ran out of saplings. plz fix.") 
end

function transferSaplingsToSingleSlot()
  for i=1,NUM_SLOTS do
    local itemDetail = turtle.getItemDetail(i)
    if itemDetail ~= nil and SAPLING_NAME == itemDetail.name and i ~= SAPLING_SLOT then
      turtle.select(i)
      turtle.transferTo(SAPLING_SLOT)
    end
  end
end

function dumpExcessSaplings()
  local sapCount = turtle.getItemCount(SAPLING_SLOT)
  local saplingsToDump = sapCount - MAX_SAPLINGS_CARRIED
  if saplingsToDump > 0 then
    turtle.select(SAPLING_SLOT)
    turtle.drop(saplingsToDump)
  end
end

function getMoreIfNeeded(itemName, suckSlot)
  for i=1,NUM_SLOTS do
    local itemDetail = turtle.getItemDetail(i)
    if itemDetail ~= nil and itemName == itemDetail.name then
      if turtle.getItemSpace(i) > 5 then
        turtle.select(suckSlot)
        turtle.suck(5)
      end
    end
  end
end
  

function forceUp()
  local success = turtle.up()
  while not success do
      turtle.digUp()
      success = turtle.up()
  end
end

function forceForward()
  local success = turtle.forward()
  while not success do
      turtle.dig()
      success = turtle.forward()
  end
end

function forceDown()
  local success = turtle.down()
  while not success do
      turtle.digDown()
      success = turtle.down()
  end
end

function forceBack()
  local success = turtle.back()
  while not success do
      turtle.turnRight()
      turtle.turnRight()
      forceForward()
      turtle.turnRight()
      turtle.turnRight()
  end
end

function detectTree()
  local found, item = turtle.inspect()
  if not found then
    print("tree farm in bad state. no sapling or tree trunk in location.")
    return false
  end
  return item.name ~= SAPLING_NAME
end

function cutTreeAndPlant()
  turtle.select(WOOD_SLOT)
  forceForward()
  local upCounter = 0
  while turtle.detectUp() do
    forceUp()
    upCounter = upCounter + 1
  end
  for i=1,upCounter do
    forceDown()
  end
  forceBack()
  turtle.select(SAPLING_SLOT)
  turtle.place()
end

function moveToNextTree()
  turtle.turnRight()
  for i=1,DISTANCE_TO_TREE do
    forceForward()
  end
  turtle.turnLeft()
end

function cutTreeRow()
  for i=1,NUM_TREES do
    if detectTree() then
      cutTreeAndPlant()
    end
    if i < NUM_TREES then
      moveToNextTree()
    end
  end
end

function goToNextTreeRow()
  turtle.turnRight()
  forceForward()
  turtle.turnLeft()
  forceUp()
  for i=1,DISTANCE_TO_ROW + 2 do
    forceForward()
  end
  turtle.turnLeft()
  forceForward()
  turtle.turnLeft()
  forceDown()
end

function cutAndReplantTrees()
  cutTreeRow()
  goToNextTreeRow()
  cutTreeRow()
  goToNextTreeRow()
end

function countWood()
  local woodCount = 0
  for i=1,NUM_SLOTS do
    local itemDetail = turtle.getItemDetail(i)
    if itemDetail ~= nil and WOOD_NAME == itemDetail.name then
      woodCount = woodCount + itemDetail.count
    end
  end
  return woodCount
end

function dropOffWood()
  local woodCount = countWood()
  local woodDropAmount = math.floor(woodCount * ((100 - COAL_PERCENTAGE) / 100))
  for i=1,NUM_SLOTS do
    if woodDropAmount > 0 then
      local itemDetail = turtle.getItemDetail(i)
      if itemDetail ~= nil and WOOD_NAME == itemDetail.name then
        turtle.select(i)
        --Assuming that woodDropAmount larger than a stack will just drop the stack
        turtle.drop(woodDropAmount)
        woodDropAmount = woodDropAmount - itemDetail.count
      end
    end
  end
  return woodCount 
end

function getFuelFromChestIfNeeded()
  turtle.select(FUEL_SLOT)
  local fuelToGet = MAX_FUEL_CARRIED - turtle.getItemCount()
  if fuelToGet > 0 then
    turtle.suck(fuelToGet)
  end
end

function goToFurnaceAndManageFuel()
  forceUp()
  turtle.turnLeft()
  forceForward()
  forceForward()
  forceForward()
  turtle.turnRight()
  forceUp()
  for i=1,DISTANCE_TO_SMELTER do
    forceForward()
  end
  turtle.select(GENERATED_FUEL_SLOT)
  turtle.suckDown()
  turtle.select(WOOD_SLOT)
  turtle.dropDown()
  turtle.turnRight()
  forceForward()
  forceDown()
  forceDown()
  forceBack()
  turtle.select(GENERATED_FUEL_SLOT)
  turtle.dropUp()
  forceForward()
  turtle.drop()
  getFuelFromChestIfNeeded()
end

function comeBackFromFurnace()
  forceUp()
  turtle.turnRight()
  for i=1,DISTANCE_TO_SMELTER do
    forceForward()
  end
  turtle.turnLeft()
  forceForward()
  forceForward()
  turtle.turnLeft()
  forceDown()
end

while true do
  refuelIfNeeded()
  cutAndReplantTrees()
  turtle.turnLeft()
  dumpExcessSaplings()
  transferSaplingsToSingleSlot()
  getMoreIfNeeded(SAPLING_NAME, SAPLING_SLOT)
  turtle.turnLeft()
  if countWood() > 20 then
    dropOffWood()
    turtle.turnRight()
    turtle.turnRight()
    goToFurnaceAndManageFuel()
    comeBackFromFurnace()
  end
  sleep(SLEEP_TIME)
end