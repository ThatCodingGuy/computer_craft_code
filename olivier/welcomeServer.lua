local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")

local radar = peripheral.find("radar")
if not radar then
  error("connect a radar.")
end
local chatBox = peripheral.find("chat_box")
if not chatBox then
  error("connect a chatBox.")
end
local RADAR_APPROX_DOOR_DISTANCE = 8.0

if not chatBox.getName() then
  chatBox.setName("PartyHouse")
end

local function greetPlayer(playerName)
  if playerName == "Corpsefire03" then
    chatBox.say(string.format("Welcome home, %s", playerName))
  else
    chatBox.say(string.format("Welcome to the party house, %s", playerName))
  end
end

local function handleRestone(eventData)
  local plateActivated = rs.getInput("top")
  if plateActivated then
    local closestPlayer = nil
    local closestDistance = 999999
    for _,player in pairs(radar.getPlayers()) do
        local distanceToRadar = math.abs(player.distance - RADAR_APPROX_DOOR_DISTANCE)
        if distanceToRadar < closestDistance then
          closestDistance = distanceToRadar
          closestPlayer = player.name
        end
    end
    if closestPlayer then
      greetPlayer(closestPlayer)
      print(string.format("greeting player: \"%s\" with distance: \"%s\"", closestPlayer, closestDistance))
    end
  end
end

local eventHandler = EventHandler.create()
eventHandler.addHandle("redstone", handleRestone)
eventHandler.pullEvents()