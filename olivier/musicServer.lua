local util = require "turboCo.util"
local json = dofile("./gitlib/turboCo/json.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")
local ScrollView = dofile("./gitlib/turboCo/ui/scrollView.lua")
local Util = dofile("./gitlib/turboCo/util.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local logger = Logger.new()
local loggingLevel = "ERROR"
if LOGGING_LEVEL then
  loggingLevel = LOGGING_LEVEL
end
Logger.log_level_filter = Logger.LoggingLevel[loggingLevel]

local TAPE_WRITE_EVENT_TYPE = "tape_write_unit"
local MUSIC_FOLDER_PATH = "/gitlib/olivier/music/"
local MUSIC_CONFIG_PATH = "musicConfig.json"
local MUSIC_PROTOCOL = "music_player"
local MUSIC_PROGRESS_TRACK_DELAY = 0.5
local BYTE_WRITE_UNIT = 10 * 1024 --10 KB


local musicConfig = nil
local selectedTapeDrive = nil
local selectedFilePath = nil
local selectedMusicConfig = nil
local musicProgressTimerId = nil
local isWritingMusic = false
local tapeSpeed = 1.0
local tapeVolume = 0.5

local eventHandler = EventHandler.create()

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

function loadMusicConfig()
  if not fs.exists(MUSIC_CONFIG_PATH) then
    musicConfig = {}
    return
  end
  local f = fs.open(MUSIC_CONFIG_PATH, 'r')
  musicConfig = json.decode(f.readAll())
  f.close()
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
    error("no tape drives found, add tape drives.")
  end
  --Figure out the last position of each tape drives
  for _,value in pairs(musicConfig) do
    local tapeDriveData = nameToTapeDriveData[value.tapeDriveName]
    if tapeDriveData == nil then
      error(string.format("tapeDrive \"%s\" is missing. Please add it back or delete the config file.", value.tapeDriveName))
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
    error("There is not enough space on any of the tape drives. Please plug in more tape drives.")
  end
  return tapeDriveToWriteTo
end

--[[
  returns first if the musicConfig is newly created,
  second has the actual config object
]]
function getMusicConfigForFileOrCreate(filePath)
  for _,value in pairs(musicConfig) do
    if value.filePath == filePath then
      return false, value
    end
  end
  local f = fs.open(filePath, "rb")
  if not f then
    error(string.format("music file on path \"%s\" not found", filePath))
  end
  local fileSize = f.seek("end")
  f.close()
  local tapeDriveData = getTapeDriveToWriteTo(fileSize)
  local newConfig = {
    filePath = filePath,
    tapeDriveName = tapeDriveData.tapeDriveName,
    tapePositionStart = tapeDriveData.startPosition,
    tapePositionEnd = tapeDriveData.startPosition + fileSize
  }
  return true, newConfig
end

function increaseSpeed(command)
  tapeSpeed = tapeSpeed + 0.1
  if tapeSpeed > 2.0 then
    tapeSpeed = 2.0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  local displayedTapeSpeed = tostring(getDisplayedTapeSpeed())
  logger.debug("increasing speed to: ", displayedTapeSpeed)
end

function decreaseSpeed(command)
  tapeSpeed = tapeSpeed - 0.1
  if tapeSpeed < 0.25 then
    tapeSpeed = 0.25
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  local displayedTapeSpeed = tostring(getDisplayedTapeSpeed())
  logger.debug("decreasing speed to: ", displayedTapeSpeed)
end

function decreaseVolume(command)
  tapeVolume = tapeVolume - 0.1
  if tapeVolume < 0 then
    tapeVolume = 0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  local displayedTapeVolume = tostring(getDisplayedTapeVolume())
  logger.debug("decreasing volume to: ", displayedTapeVolume)
end

function increaseVolume(command)
  tapeVolume = tapeVolume + 0.1
  if tapeVolume > 1 then
    tapeVolume = 1
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  local displayedTapeVolume = tostring(getDisplayedTapeVolume())
  logger.debug("decreasing volume to: ", displayedTapeVolume)
end

function getAllMusicAndCreateButtons()
  local searchTerm = MUSIC_FOLDER_PATH .. "*.dfpwm"
  local files = fs.find(searchTerm)
  logger.debug("looking for files on path: ", searchTerm)
  for _,f in pairs(files) do
    local name = fs.getName(f)
    logger.debug("found music file with name: ", name)
  end
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
  if musicProgressTimerId == timerId and not isWritingMusic then
    local position = selectedTapeDrive.getPosition()
    if position > selectedMusicConfig.tapePositionEnd then
      position = selectedMusicConfig.tapePositionEnd
      seekTapeToPosition(position)
      selectedTapeDrive.stop()
    else
      musicProgressTimerId = os.startTimer(MUSIC_PROGRESS_TRACK_DELAY)
    end
    local relativePosition = position - selectedMusicConfig.tapePositionStart
    local relativeEnd = selectedMusicConfig.tapePositionEnd - selectedMusicConfig.tapePositionStart
    local percentage = math.floor((relativePosition / relativeEnd) * 100)
    progressDisplay.updateText{text = string.format("Progress: %s%%", percentage), render=true}
  end
end

function playTapeFromConfig(config)
  setupTapeFromConfig(config)
  progressDisplay.updateText{text = "Progress: 0%", render=true}
  musicProgressTimerId = os.startTimer(MUSIC_PROGRESS_TRACK_DELAY)
  selectedTapeDrive.play()
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
  local progressText = string.format("Writing: %s%% complete", percentage)
  progressDisplay.updateText{text=progressText, render=true}

  --Stop if done, and actually play the tape, if not, put another event in the queue
  if maxByte == fileSize then
    logger.debug("writing new music done: ", fileSize, " bytes written.")
    progressDisplay.updateText{text="", render=true}
    addAndPersistMusicConfig(config)
    playTapeFromConfig(config)
    isWritingMusic = false
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

function play(command)
  local selected = radioGroup.getSelected()
  if not isWritingMusic and selected ~= nil then
    local filePath = selected.getId()
    logger.debug("filePath: ", filePath)
    logger.debug("currentSelectedFilePath: ", tostring(selectedFilePath))
    local isNew, config = getMusicConfigForFileOrCreate(filePath)
    if selectedFilePath == filePath then
      --resume if we are already loaded
      selectedTapeDrive.play()
    elseif isNew then
      --if this is a new config, write the new song to the tape
      queueWrite(config)
    else
      logger.debug("config: " .. textutils.serializeJSON(config))
      --if config is already written, then we simply play from it
      playTapeFromConfig(config)
    end
  end
end

function stop(command)
  if selectedTapeDrive ~= nil and not isWritingMusic then
    selectedTapeDrive.stop()
  end
end

function getMusicList()

end

local commandToFunc = {
  ['get_music_list']=getMusicList,
  ['stop']=stop,
  ['play']=play,
  ['increase_speed']=increaseSpeed,
  ['decrease_speed']=decreaseSpeed,
  ['increase_volume']=increaseVolume
}

function rednetMessageReceived(eventData)
  local senderId, message, protocol = eventData[2], eventData[3], eventData[4]
  if protocol ~= MUSIC_PROTOCOL then
    return
  end
  local messageObj = json.decode(message)
  if messageObj == nil or messageObj.command == nil then
    local responseObj = {
      error='No command was sent. Write a command in the top-level \"command\" field.'
    }
    rednet.send(senderId, json.encode(responseObj), MUSIC_PROTOCOL)
    return
  end
  local commandFunc = commandToFunc[messageObj.command]
  if not commandFunc then
    local responseObj = {
      error=string.format('Invalid command "%s" sent.', messageObj.command)
    }
    rednet.send(senderId, json.encode(responseObj), MUSIC_PROTOCOL)
    return
  end
  commandFunc(messageObj)
end

getAllMusicAndCreateButtons()

eventHandler.addHandle(TAPE_WRITE_EVENT_TYPE, writeTapeUnit)
eventHandler.addHandle("timer", musicProgressTrack)
eventHandler.addHandle("rednet_message", rednetMessageReceived)

loadMusicConfig()

--Loops until exit handle quits it
eventHandler.pullEvents()