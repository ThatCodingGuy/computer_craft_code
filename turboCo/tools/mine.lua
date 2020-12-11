local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local Miner = dofile("./gitlib/turboCo/tools/miner.lua")

Miner.new(EventHandler.create()).start()
