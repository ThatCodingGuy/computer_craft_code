--- Puts the turtle in a manual control state for mining.

local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local Miner = dofile("./gitlib/turboCo/tools/miner.lua")

Miner.new(EventHandler.create()).start()
