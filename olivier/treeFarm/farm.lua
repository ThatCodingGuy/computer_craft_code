local FUEL_SLOT = 16
local SAPLING_SLOT = 15
local WOOD_SLOT = 1

local SAPLING_NAME = "minecraft:sapling"
local FUEL_NAME = "minecraft:coal"

local NUM_TREES = 6
local DISTANCE_TO_TREE = 3
local DISTANCE_TO_ROW = 4
local NUM_SLOTS = 16

local SLEEP_TIME = 180 -- 3 mins

function refuelIfNeeded()
  if turtle.getFuelLevel() < 200 then
    for i=1,NUM_SLOTS do
      local itemDetail = turtle.getItemDetail(i)
      if itemDetail ~= nil and FUEL_NAME == itemDetail.name then
        turtle.select(i)
        turtle.refuel(3)
        turtle.select(WOOD_SLOT)
        return
      end
    end
    print("Ran out of fuel. plz fix.") 
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

function getMoreIfNeeded(itemName)
  for i=1,NUM_SLOTS do
    local itemDetail = turtle.getItemDetail(i)
    if itemDetail ~= nil and itemName == itemDetail.name then
      if turtle.getItemSpace(i) > 5 then
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

while true do
  refuelIfNeeded()
  cutAndReplantTrees()
  turtle.turnLeft()
  getMoreIfNeeded(SAPLING_NAME)
  turtle.turnLeft()
  getMoreIfNeeded(FUEL_NAME)
  turtle.turnLeft()
  turtle.turnLeft()
  sleep(SLEEP_TIME)
end