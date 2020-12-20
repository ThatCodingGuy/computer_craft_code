local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")

local customEntranceDialogues = {
  ['corpsefire03'] = {
    "Welcome home, master Olivier."
  },
  ['shasta_the_dude'] = {
    "YOOOOO, LEOOOOOOOOOO",
    "Leo, wazzzzzzzzaaaaaaaaa",
    "Welcome Leo, Lord of the purple sheep.",
    "Hello Leo, master of saxophone",
  },
  ['live4pie'] = {
    "Mathieu, WAZAAAAAAAAAAAAAAA",
    "Welcome Mathieu, please don't bring endermen or withers with you",
    "Welcome Mathieu, and no, you may not have more wool.",
    "Welcome Mathieu, the music R&D project still accepts more ender pearls.",
    "Hey Mathieu, remember to craft more bofa when you get back home."
  },
  ['muskadrin'] = {
    "YOOOOOO KATHERINE",
    "Bienvenue Katherine, PagerDuty extraordinaire",
    "Salut Katherine, please do not play badminton inside",
  },
  ['nazenserie'] = {
    "Bienvenue Pierro, please leave the lawsuits at the door",
    "Bonjour Pierro, master of IndustrialCraft",
    "Salut Pierro, putting a quarry on my house would be BM and is not allowed"
  }
}

local playerNameOverrides = {
  ['shasta_the_dude'] = "Leo",
  ['live4pie'] = "Mathieu",
  ['muskadrin'] = "Katherine",
  ['nazenserie'] = "Pierro"
}

local lastMessageTimeForPlayer = {}


local radar = peripheral.find("radar")
if not radar then
  error("connect a radar.")
end
local chatBox = peripheral.find("chat_box")
if not chatBox then
  error("connect a chatBox.")
end
local RADAR_APPROX_DOOR_DISTANCE = 4.6
local MINIMUM_EPOCH_TIME_ELAPSED = 5000 --5 seconds

if not chatBox.getName() then
  chatBox.setName("PartyHouse")
end

local function shouldMessage(playerName)
  local lastWelcomeTime = lastMessageTimeForPlayer[playerName]
  if not lastWelcomeTime then
    lastMessageTimeForPlayer[playerName] = os.epoch("utc")
    return true
  end
  local currentTime = os.epoch("utc")
  if currentTime - lastWelcomeTime > MINIMUM_EPOCH_TIME_ELAPSED then
    lastMessageTimeForPlayer[playerName] = currentTime
    return true
  else
    return false
  end
end

local function greetPlayerIfNeeded(playerName)
  if not shouldMessage(playerName) then
    return
  end
  local customDialogues = customEntranceDialogues[string.lower(playerName)]
  if customDialogues then
    local dialogIndex = math.floor(math.random() * #customDialogues) + 1
    chatBox.say(customDialogues[dialogIndex])
  else
    chatBox.say(string.format("Welcome to the party house, %s", playerName))
  end
end

local function exitPlayerIfNeeded(playerName)
  if not shouldMessage(playerName) then
    return
  end
  local greetingName = playerNameOverrides[string.lower(playerName)]
  if not greetingName then
    greetingName = playerName
  end
  if playerName == "Corpsefire03" then
    chatBox.say(string.format("Have a nice trip, Master Olivier"))
  else
    chatBox.say(string.format("Welcome to the party house, %s", greetingName))
  end
end

local function handleRestone(eventData)
  local welcomePlateActivated = rs.getInput("top")
  local exitPlateActivated = rs.getInput("left")
  if welcomePlateActivated or exitPlateActivated then
    local closestPlayer = nil
    local closestDistance = 999999
    for _,player in ipairs(radar.getPlayers()) do
        local distanceToRadar = math.abs(player.distance - RADAR_APPROX_DOOR_DISTANCE)
        if distanceToRadar < closestDistance then
          closestDistance = distanceToRadar
          closestPlayer = player
        end
    end
    if closestPlayer then
      if welcomePlateActivated then
        greetPlayerIfNeeded(closestPlayer.name)
      elseif exitPlateActivated then
        exitPlayerIfNeeded(closestPlayer.name)
      end
      print(string.format("greeting player: \"%s\" with distance to plate: \"%s\". distance to radar: \"%s\"", closestPlayer.name, closestDistance, closestPlayer.distance))
    end
  end
end

local eventHandler = EventHandler.create()
eventHandler.addHandle("redstone", handleRestone)
eventHandler.pullEvents()