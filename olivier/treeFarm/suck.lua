local FUEL_SLOT = 16
local SAPLING_SLOT = 1
local RANDOM_SHIT_SLOT = 2

local SAPLING_NAME = "minecraft:sapling"
local ACCEPTABLE_FUELS = { "minecraft:coal" }

local MAX_SAPLING_AMOUNT = 10
local DISTANCE_TO_CHEST = 11
local NUM_SLOTS = 16

function refuelIfNeeded()
  local slot = turtle.getSelectedSlot()
  if turtle.getFuelLevel() < 200 then
    turtle.select(FUEL_SLOT)
    turtle.refuel()
  end
  turtle.select(slot)
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

function dropOffAndComeBack()
  refuelIfNeeded()
  turtle.select(RANDOM_SHIT_SLOT)
  forceDown()
  forceDown()
  for i=1,DISTANCE_TO_CHEST do
    forceForward()
  end
  forceUp()
  forceUp()
  forceUp()
  forceUp()
  turtle.turnRight()
  forceForward()

  turtle.select(SAPLING_SLOT)
  turtle.drop()
  turtle.select(RANDOM_SHIT_SLOT)

  turtle.turnRight()
  turtle.turnRight()
  forceForward()
  forceDown()
  forceDown()
  forceDown()
  forceDown()
  turtle.turnLeft()
  for i=1,DISTANCE_TO_CHEST do
    forceForward()
  end
  forceUp()
  forceUp()
  turtle.turnLeft()
  turtle.turnLeft()
end

function collectSapling()
  turtle.select(SAPLING_SLOT)
  turtle.suck()
end

while true do
  collectSapling()
  if turtle.getItemCount(SAPLING_SLOT) > 10 then
    dropOffAndComeBack()
  end
end