local json = dofile("./gitlib/turboCo/json.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")

local TAPE_WRITE_EVENT_TYPE = "tape_write_unit"
local MUSIC_FOLDER_PATH = "/gitlib/olivier/music/"
local MUSIC_CONFIG_PATH = "musicConfig.json"
local BYTE_WRITE_UNIT = 10 * 1024 --10 KB

local screen = peripheral.find("monitor")
if screen == nil then
  screen = term.current()
end
local width,height = screen.getSize()

local musicConfig = nil
local selectedTapeDrive = nil
local selectedFilePath = nil
local isWritingMusic = false
local tapeSpeed = 1.0
local tapeVolume = 0.5

local eventHandler = EventHandler.create()
local exitHandler = ExitHandler.createFromScreen(screen, eventHandler)
local progressDisplay = nil
local speedScreenContent = nil
local volumeScreenContent = nil
local controlScreenBuffer = nil

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
  musicConfig = json.decode(f.read("*all"))
  f.close()
end

function addAndPersistMusicConfig(config)
  local f = fs.open(MUSIC_CONFIG_PATH, 'w')
  table.insert(musicConfig, config)
  f.write(json.encode(musicConfig))
  f.close()
end

function getTapeDriveToWriteTo(fileSize)
  local nameToTapeDriveData = {}
  for _,periphName in pairs(peripheral.getNames()) do
    local periphType = peripheral.getType(periphName)
    if periphType == "tape_drive" then
      local tapeDrive = peripheral.wrap(periphName)
      nameToTapeDriveData[periphName] = {
        tapeDrive=tapeDrive,
        lastPosition=0
      }
    end
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
          tapeDrive = tapeDriveData.tapeDrive,
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
    tapeDrive = tapeDriveData.tapeDrive,
    tapeDriveName = tapeDriveData.tapeDriveName,
    tapePositionStart = tapeDriveData.startPosition,
    tapePositionEnd = tapeDriveData.startPosition + fileSize - 1
  }
  return true, newConfig
end

function increaseSpeed()
  tapeSpeed = tapeSpeed + 0.1
  if tapeSpeed > 2.0 then
    tapeSpeed = 2.0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  speedScreenContent.updateText{text=tostring(getDisplayedTapeSpeed()), render=true}
end

function decreaseSpeed()
  tapeSpeed = tapeSpeed - 0.1
  if tapeSpeed < 0.25 then
    tapeSpeed = 0.25
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setSpeed(tapeSpeed)
  end
  speedScreenContent.updateText{text=tostring(getDisplayedTapeSpeed()), render=true}
end

function decreaseVolume()
  tapeVolume = tapeVolume - 0.1
  if tapeVolume < 0 then
    tapeVolume = 0
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  volumeScreenContent.updateText{text=tostring(getDisplayedTapeVolume()), render=true}
end

function increaseVolume()
  tapeVolume = tapeVolume + 0.1
  if tapeVolume > 1 then
    tapeVolume = 1
  end
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.setVolume(tapeVolume)
  end
  volumeScreenContent.updateText{text=tostring(getDisplayedTapeVolume()), render=true}
end

local screenTitleBuffer = ScreenBuffer.createFromOverrides{screen=screen, height=1, bgColor=colors.yellow, textColor=colors.gray}
screenTitleBuffer.writeCenter{text="-- Music Player --"}
Button.create{
  screenBuffer=screenTitleBuffer,
  screenBufferWriteFunc=screenTitleBuffer.writeRight,
  eventHandler=eventHandler,
  text=" x",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=exitHandler.exit
}
screenTitleBuffer.render()

controlScreenBuffer = ScreenBuffer.createFromOverrides{screen=screen, height=1,topOffset=1, bgColor=colors.blue, textColor=colors.white}
controlScreenBuffer.write{text="  "}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="+",
  textColor=colors.white,
  bgColor=colors.green,
  leftClickCallback=increaseSpeed
}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="-",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=decreaseSpeed
}
controlScreenBuffer.write{text=" Speed: "}

speedScreenContent = ScreenContent.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text=getDisplayedTapeSpeed()
}

--Adds padding
controlScreenBuffer.write{text="        "}

Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="+",
  textColor=colors.white,
  bgColor=colors.green,
  leftClickCallback=increaseVolume
}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="-",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=decreaseVolume
}

controlScreenBuffer.write{text=" Volume: "}
volumeScreenContent = ScreenContent.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text=getDisplayedTapeVolume()
}
controlScreenBuffer.render()

local screenBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=2, bottomOffset=2, bgColor=colors.purple, textColor=colors.white}
screenBuffer.ln()
local radioGroup = RadioGroup.create()

function getAllMusicAndCreateButtons(radioGroup)
  local searchTerm = MUSIC_FOLDER_PATH .. "*.dfpwm"
  local files = fs.find(searchTerm)
  for _,f in pairs(files) do
    local name = fs.getName(f)
    radioGroup.addRadioInput(RadioInput.create{
      id=f,
      title=name,
      screenBuffer=screenBuffer,
      screenBufferWriteFunc=screenBuffer.writeLn,
      eventHandler=eventHandler
    })
  end
end

function setupTapeFromConfig(config)
  selectedTapeDrive = config.tapeDrive
  selectedFilePath = config.filePath
  local seekAmount = config.tapePositionStart - selectedTapeDrive.getPosition()
  selectedTapeDrive.seek(seekAmount)
  selectedTapeDrive.setSpeed(tapeSpeed)
  selectedTapeDrive.setVolume(tapeVolume)
end

function playTapeFromConfig(config)
  setupTapeFromConfig(config)
  selectedTapeDrive.play()
end

function writeTapeUnit(eventData)
  local config, currFilePosition = eventData[2], eventData[3]
  print()
  print(config)
  print(config.tapeDrive.write)
  print(config.tapeDriveName)
  local fileSize = config.tapePositionEnd - config.tapePositionStart
  local maxByte = currFilePosition + BYTE_WRITE_UNIT
  if maxByte > fileSize then
    maxByte = config.tapePositionEnd
  end
  local sourceFile = fs.open(config.filePath, "rb")
  sourceFile.seek("set", currFilePosition)
  for i=currFilePosition,maxByte do
    local byte = sourceFile.read()
    if byte then
      config.tapeDrive.write(byte)
    end
  end
  local percentage = math.floor((maxByte / config.tapePositionEnd) * 100)
  --Update screen with progress
  local progressText = string.format("Writing: %s%% complete", percentage)
  progressDisplay.updateText{text=progressText, render=true}

  --Stop if done, and actually play the tape, if not, put another event in the queue
  if maxByte == config.tapePositionEnd then
    progressDisplay.updateText{text="", render=true}
    addAndPersistMusicConfig(config)
    playTapeFromConfig(config)
    isWritingMusic = false
  else
    os.queueEvent(TAPE_WRITE_EVENT_TYPE, config, maxByte + 1)
  end
  sourceFile.close()
end

function queueWrite(config)
  if selectedTapeDrive ~= nil then
    selectedTapeDrive.stop()
  end
  isWritingMusic = true
  setupTapeFromConfig(config)
  print(config)
  print(config.tapeDrive.write)
  print(config.tapeDriveName)
  os.queueEvent(TAPE_WRITE_EVENT_TYPE, config, 0)
end

function play()
  if not isWritingMusic then
    local filePath = radioGroup.getSelected().getId()
    local isNew, config = getMusicConfigForFileOrCreate(filePath)
    if selectedFilePath == filePath then
      --resume if we are already loaded
      selectedTapeDrive.play()
    elseif isNew then
      --if this is a new config, write the new song to the tape
      queueWrite(config)
    else
      --if config is already written, then we simply play from it
      playTapeFromConfig(config)
    end
  end
end

function stop()
  if selectedTapeDrive ~= nil and not isWritingMusic then
    selectedTapeDrive.stop()
  end
end

getAllMusicAndCreateButtons(radioGroup)
screenBuffer.render()

local screenBottomBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=height-2, height=2, bgColor=colors.yellow, textColor=colors.white}
local playButton = Button.create{
  screenBuffer=screenBottomBuffer,
  screenBufferWriteFunc=screenBottomBuffer.writeLeft,
  eventHandler=eventHandler, 
  text=" Play ", 
  textColor=colors.white, 
  bgColor=colors.green,
  leftClickCallback=play
}

local stopButton = Button.create{
  screenBuffer=screenBottomBuffer,
  screenBufferWriteFunc=screenBottomBuffer.writeRight,
  eventHandler=eventHandler, 
  text=" Stop ", 
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=stop
}

progressDisplay = ScreenContent.create{
  screenBuffer=screenBottomBuffer,
  screenBufferWriteFunc=screenBottomBuffer.writeCenter,
  text="",
}
screenBottomBuffer.render()
eventHandler.addHandle(TAPE_WRITE_EVENT_TYPE, writeTapeUnit)

loadMusicConfig()

--Loops until exit handle quits it
eventHandler.pullEvents()