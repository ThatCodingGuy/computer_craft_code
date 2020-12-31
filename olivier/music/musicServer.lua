local json = dofile("./gitlib/turboCo/json.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local Util = dofile("./gitlib/turboCo/util.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local MusicConstants = dofile("./gitlib/olivier/music/musicConstants.lua")
local logger = Logger.new()
local loggingLevel = "ERROR"
if LOGGING_LEVEL then
  loggingLevel = LOGGING_LEVEL
end
Logger.log_level_filter = Logger.LoggingLevel[loggingLevel]

os.loadAPI('./gitlib/turboCo/modem.lua')
modem.openModems()

local TAPE_WRITE_EVENT_TYPE = "tape_write_unit"
local MUSIC_FOLDER_PATH = "/gitlib/olivier/music/songs/"
local MUSIC_CONFIG_PATH = "musicConfig.json"
local MUSIC_PROGRESS_TRACK_DELAY = 0.5
local BYTE_WRITE_UNIT = 10 * 1024 --10 KB

local connectedClients = {}
local musicConfig = nil
local musicList = nil
local selectedTapeDrive = nil
local selectedFilePath = nil
local selectedMusicConfig = nil
local musicProgressTimerId = nil
local isWritingMusic = false
local tapeSpeed = 1.0
local tapeVolume = 0.5

local eventHandler = EventHandler.create()

local function isTapeStopped()
  return selectedTapeDrive == nil or selectedTapeDrive.getState() == "STOPPED"
end

local function sendMessageToClient(senderId, messageObj)
  local message = json.encode(messageObj)
  rednet.send(senderId, message, MusicConstants.MUSIC_CLIENT_PROTOCOL)
end

local function sendMessageToClients(messageObj)
  local message = json.encode(messageObj)
  rednet.broadcast(message, MusicConstants.MUSIC_CLIENT_PROTOCOL)
end

local function validateNotNil(senderId, messageObj, objPath)
  if not messageObj and messageObj[objPath] then
    sendMessageToClient(senderId, {error=string.format('message is missing parameter: \"%s\"', objPath)})
    return false
  end
  return true
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function getDisplayedTapeSpeed()
  return string.format("%sx", round(tapeSpeed, 2))
end

local function getDisplayedTapeVolume()
  return string.format("%s%%", math.floor(round(tapeVolume, 2) * 100))
end

function getAllMusicAndCreateMusicList()
  local searchTerm = MUSIC_FOLDER_PATH .. "*.dfpwm"
  local files = fs.find(searchTerm)
  logger.debug("looking for files on path: ", searchTerm)
  musicList = {}
  for _,f in pairs(files) do
    local name = fs.getName(f)
    logger.debug("found music file with name: ", name) 
    table.insert(musicList, {filePath=f, fileName=fs.getName(f)})
  end
end

function loadMusicConfig()
  if not fs.exists(MUSIC_CONFIG_PATH) then
    musicConfig = {}
    return
  end
  local f = fs.open(MUSIC_CONFIG_PATH, 'r')
  musicConfig = json.decode(f.readAll())
  f.close()
  getAllMusicAndCreateMusicList()
end

function addAndPersistMusicConfig(config)
  table.insert(musicConfig, config)
  local f = fs.open(MUSIC_CONFIG_PATH, 'w')
  if f then
    f.write(json.encode(musicConfig))
    f.close()
  end
end

function getTapeDriveToWriteTo(fileSize)
  local nameToTapeDriveData = {}
  local tapeDrives = Util.findPeripherals("tape_drive")
  for _,tapeDrive in pairs(tapeDrives) do
    nameToTapeDriveData[tapeDrive.name] = {
      tapeDrive=tapeDrive.periph,
      lastPosition=-1
    }
  end
  local hasTapeDrives = false
  for _,_ in pairs(nameToTapeDriveData) do
    hasTapeDrives = true
  end
  if not hasTapeDrives then
    sendMessageToClients({error="no tape drives found, add tape drives."})
    return false
  end
  --Figure out the last position of each tape drives
  for _,value in pairs(musicConfig) do
    local tapeDriveData = nameToTapeDriveData[value.tapeDriveName]
    if tapeDriveData == nil then
      sendMessageToClients({error=(string.format("tapeDrive \"%s\" is missing. Please add it back or delete the music server config file.", value.tapeDriveName))})
      return false
    end
    if value.tapePositionEnd > tapeDriveData.lastPosition then
      tapeDriveData.lastPosition = value.tapePositionEnd
    end
  end
  local tapeDriveToWriteTo = nil
  --Figure out the tapeDrive with the smallest remaining valid size
  for tapeDriveName,tapeDriveData in pairs(nameToTapeDriveData) do
    local remainingSize = tapeDriveData.tapeDrive.getSize() - tapeDriveData.lastPosition
    if remainingSize > fileSize and (tapeDriveToWriteTo == nil or (remainingSize < tapeDriveToWriteTo.remainingSize)) then
        tapeDriveToWriteTo = {
          tapeDriveName = tapeDriveName,
          remainingSize = remainingSize,
          startPosition = tapeDriveData.lastPosition + 1
        }
    end
  end
  if tapeDriveToWriteTo == nil then
    sendMessageToClients({error="There is not enough space on any of the tape drives. Please plug in more tape drives."})
    return false
  end
  return true, tapeDriveToWriteTo
end

--[[
  returns first if getting the music config was successful
          second if the musicConfig is newly created,
          third has the actual config object
]]
function getMusicConfigForFileOrCreate(senderId, filePath)
  for _,value in pairs(musicConfig) do
    if value.filePath == filePath then
      return true, false, value
    end
  end
  local f = fs.open(filePath, "rb")
  if not f then
    sendMessageToClient(senderId, {error=string.format("music file on path \"%s\" not found", filePath)})
    return false, false, nil
  end
  local fileSize = f.seek("end")
  f.close()
  local success, tapeDriveData = getTapeDriveToWriteTo(fileSize)
  local newConfig = nil
  if success then
    newConfig = {
      filePath = filePath,
      tapeDriveName = tapeDriveData.tapeDriveName,
      tapePositionStart = tapeDriveData.startPosition,
      tapePositionEnd = tapeDriveData.startPosition + fileSize
    }
  end
  return success, true, newConfig
end

function seekTapeToPosition(tapePosition)
  local seekAmount = tapePosition - selectedTapeDrive.getPosition()
  selectedTapeDrive.seek(seekAmount)
end

function setupTapeFromConfig(config)
  selectedMusicConfig = config
  selectedTapeDrive = peripheral.wrap(config.tapeDriveName)
  selectedFilePath = config.filePath
  seekTapeToPosition(config.tapePositionStart)
  selectedTapeDrive.setSpeed(tapeSpeed)
  selectedTapeDrive.setVolume(tapeVolume)
end

function musicProgressTrack(eventData)
  local timerId = eventData[2]
  if musicProgressTimerId == timerId and not isWritingMusic and not isTapeStopped() then
    local position = selectedTapeDrive.getPosition()
    if position > selectedMusicConfig.tapePositionEnd then
      position = selectedMusicConfig.tapePositionEnd
      seekTapeToPosition(position)
      stopTape()
    else
      musicProgressTimerId = os.startTimer(MUSIC_PROGRESS_TRACK_DELAY)
    end
    local relativePosition = position - selectedMusicConfig.tapePositionStart
    local relativeEnd = selectedMusicConfig.tapePositionEnd - selectedMusicConfig.tapePositionStart
    local percentage = math.floor((relativePosition / relativeEnd) * 100)
    sendMessageToClients({command=MusicConstants.PLAYING_PROGRESS_RESPONSE_TYPE, filePath=selectedFilePath, fileName=fs.getName(selectedFilePath), percentage=percentage})
  end
end

function playTape()
  selectedTapeDrive.play()
  sendMessageToClients({command=MusicConstants.PLAY_COMMAND, filePath=selectedFilePath, fileName=fs.getName(selectedFilePath)})
end

function stopTape()
  if selectedTapeDrive ~= nil and not isWritingMusic then
    selectedTapeDrive.stop()
    sendMessageToClients({command=MusicConstants.STOP_COMMAND, filepath=selectedFilePath, stopped=true})
  end
end

function playTapeFromConfig(config)
  setupTapeFromConfig(config)
  musicProgressTimerId = os.startTimer(MUSIC_PROGRESS_TRACK_DELAY)
  playTape()
end

function writeTapeUnit(eventData)
  local config, currFilePosition = eventData[2], eventData[3]
  local tapeDrive = peripheral.wrap(config.tapeDriveName)
  local fileSize = config.tapePositionEnd - config.tapePositionStart
  local maxByte = currFilePosition + BYTE_WRITE_UNIT
  if maxByte > fileSize then
    maxByte = fileSize
  end
  local sourceFile = fs.open(config.filePath, "rb")
  sourceFile.seek("set", currFilePosition)
  for i=currFilePosition,maxByte do
    local byte = sourceFile.read()
    if byte then
      tapeDrive.write(byte)
    end
  end
  sourceFile.close()
  local percentage = math.floor((maxByte / fileSize) * 100)
  --Update screen with progress
  sendMessageToClients({command=MusicConstants.TAPE_WRITE_PROGRESS_RESPONSE_TYPE, filePath=selectedFilePath, fileName=fs.getName(selectedFilePath), percentage=percentage})

  --Stop if done, and actually play the tape, if not, put another event in the queue
  if maxByte == fileSize then
    logger.debug("writing new music done: ", fileSize, " bytes written.")
    isWritingMusic = false
    addAndPersistMusicConfig(config)
    playTapeFromConfig(config)
  else
    os.queueEvent(TAPE_WRITE_EVENT_TYPE, config, maxByte + 1)
  end
end

function queueWrite(config)
  logger.debug("queue writing new music")
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.stop()
  end
  isWritingMusic = true
  setupTapeFromConfig(config)
  os.queueEvent(TAPE_WRITE_EVENT_TYPE, config, 0)
end

function play(senderId, messageObj)
  if not validateNotNil(senderId, messageObj, 'filePath') then
    return
  end
  if not isWritingMusic then
    local filePath = messageObj.filePath
    logger.debug("filePath: ", filePath)
    logger.debug("currentSelectedFilePath: ", selectedFilePath)
    local success, isNew, config = getMusicConfigForFileOrCreate(senderId, filePath)
    if not success then
      --We failed to get the music config and already sent an error message
      return
    elseif selectedFilePath == filePath then
      --resume if we are already loaded
      playTape()
    elseif isNew then
      --if this is a new config, write the new song to the tape
      queueWrite(config)
    else
      --logger.debug("config: ", textutils.serializeJSON(config))
      --if config is already written, then we simply play from it
      playTapeFromConfig(config)
    end
  end
end

function stop(senderId, messageObj)
  stopTape()
end

function getMusicState(senderId, messageObj)
  local fileName = nil
  if selectedFilePath ~= nil then
    fileName = fs.getName(selectedFilePath)
  end
  sendMessageToClient(senderId, {
    command=MusicConstants.GET_MUSIC_STATE_COMMAND,
    musicList=musicList,
    filePath=selectedFilePath,
    fileName=fileName,
    tapeSpeed=getDisplayedTapeSpeed(),
    tapeVolume=getDisplayedTapeVolume()
  })
end

function increaseSpeed(senderId, messageObj)
  tapeSpeed = tapeSpeed + 0.1
  if tapeSpeed > 2.0 then
    tapeSpeed = 2.0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  local displayedTapeSpeed = tostring(getDisplayedTapeSpeed())
  logger.debug("increasing speed to: ", displayedTapeSpeed)
  sendMessageToClients({command=MusicConstants.INCREASE_SPEED_COMMAND, tapeSpeed=displayedTapeSpeed})
end

function decreaseSpeed(senderId, messageObj)
  tapeSpeed = tapeSpeed - 0.1
  if tapeSpeed < 0.25 then
    tapeSpeed = 0.25
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  local displayedTapeSpeed = tostring(getDisplayedTapeSpeed())
  logger.debug("decreasing speed to: ", displayedTapeSpeed)
  sendMessageToClients({command=MusicConstants.DECREASE_SPEED_COMMAND, tapeSpeed=displayedTapeSpeed})
end

function decreaseVolume(senderId, messageObj)
  tapeVolume = tapeVolume - 0.1
  if tapeVolume < 0 then
    tapeVolume = 0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  local displayedTapeVolume = tostring(getDisplayedTapeVolume())
  logger.debug("decreasing volume to: ", displayedTapeVolume)
  sendMessageToClients({command=MusicConstants.DECREASE_VOLUME_COMMAND, tapeVolume=displayedTapeVolume})
end

function increaseVolume(senderId, messageObj)
  tapeVolume = tapeVolume + 0.1
  if tapeVolume > 1 then
    tapeVolume = 1
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  local displayedTapeVolume = tostring(getDisplayedTapeVolume())
  logger.debug("increasing volume to: ", displayedTapeVolume)
  sendMessageToClients({command=MusicConstants.INCREASE_VOLUME_COMMAND, tapeVolume=displayedTapeVolume})
end

local commandToFunc = {
  [MusicConstants.GET_MUSIC_STATE_COMMAND]=getMusicState,
  [MusicConstants.STOP_COMMAND]=stop,
  [MusicConstants.PLAY_COMMAND]=play,
  [MusicConstants.INCREASE_SPEED_COMMAND]=increaseSpeed,
  [MusicConstants.DECREASE_SPEED_COMMAND]=decreaseSpeed,
  [MusicConstants.INCREASE_VOLUME_COMMAND]=increaseVolume,
  [MusicConstants.DECREASE_VOLUME_COMMAND]=decreaseVolume
}

function rednetMessageReceived(eventData)
  local senderId, message, protocol = eventData[2], eventData[3], eventData[4]
  logger.debug("senderId: ", senderId, "protocol: ", protocol, "message: ", message)
  if protocol ~= MusicConstants.MUSIC_SERVER_PROTOCOL then
    return
  end
  local messageObj = json.decode(message)
  if not validateNotNil(senderId, messageObj, 'command') then
    return
  end
  local commandFunc = commandToFunc[messageObj.command]
  if not commandFunc then
    sendMessageToClient(senderId, {error=string.format('Invalid command "%s" sent.', messageObj.command)})
    return
  end
  commandFunc(senderId, messageObj)
end

eventHandler.addHandle(TAPE_WRITE_EVENT_TYPE, writeTapeUnit)
eventHandler.addHandle("timer", musicProgressTrack)
eventHandler.addHandle("rednet_message", rednetMessageReceived)

loadMusicConfig()

local computerLabel = os.getComputerLabel()
if computerLabel == nil then
  error('need to define a computer label to use this server.')
end
rednet.host(MusicConstants.MUSIC_SERVER_PROTOCOL, computerLabel)

--Loops until exit handle quits it
eventHandler.pullEvents()