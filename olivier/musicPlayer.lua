local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")

local TAPE_WRITE_EVENT_TYPE = "tape_write_unit"
local MUSIC_FOLDER_PATH = "/gitlib/olivier/music/"
local BYTE_WRITE_UNIT = 10 * 1024 --10 KB

local screen = peripheral.find("monitor")
if screen == nil then
  screen = term.current()
end

local tapeDrive = peripheral.find("tape_drive")
local tapeSpeed = 1.0
local tapeVolume = 0.5

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function getRealTapeSpeed()
  return round(tapeSpeed, 2)
end

local function getRealTapeVolume()
  return round(tapeVolume, 2)
end

if tapeDrive ~= nil then
  tapeDrive.setVolume(getRealTapeVolume())
  tapeDrive.setSpeed(getRealTapeSpeed())
end

local eventHandler = EventHandler.create()
local exitHandler = ExitHandler.createFromScreen(screen, eventHandler)
local progressDisplay = nil
local isWritingMusic = false
local currentFileWrittenToTape = nil
local speedScreenContent = nil
local volumeScreenContent = nil
local controlScreenBuffer = nil

function increaseSpeed()
  tapeSpeed = tapeSpeed + 0.1
  if tapeSpeed > 2.0 then
    tapeSpeed = 2.0
  end
  tapeDrive.setSpeed(tapeSpeed)
  speedScreenContent.updateText{text=tostring(getRealTapeSpeed()), render=true}
end

function decreaseSpeed()
  tapeSpeed = tapeSpeed - 0.1
  if tapeSpeed < 0.25 then
    tapeSpeed = 0.25
  end
  tapeDrive.setSpeed(tapeSpeed)
  speedScreenContent.updateText{text=tostring(getRealTapeSpeed()), render=true}
end

function decreaseVolume()
  tapeVolume = tapeVolume - 0.1
  if tapeVolume < 0 then
    tapeVolume = 0
  end
  tapeDrive.setVolume(tapeVolume)
  volumeScreenContent.updateText{text=tostring(getRealTapeVolume()), render=true}
end

function increaseVolume()
  tapeVolume = tapeVolume + 0.1
  if tapeVolume > 10 then
    tapeVolume = 10
  end
  tapeDrive.setVolume(tapeVolume)
  volumeScreenContent.updateText{text=tostring(getRealTapeVolume()), render=true}
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
  text=tostring(tapeSpeed)
}

--Adds padding
controlScreenBuffer.write{text="      "}

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
  text=tostring(tapeVolume)
}
controlScreenBuffer.render()

local screenBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=2, bgColor=colors.purple, textColor=colors.white}
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

function writeTapeUnit(eventData)
  local filePath, currByteCounter, fileSize = eventData[2], eventData[3], eventData[4]
  local maxByte = currByteCounter + BYTE_WRITE_UNIT
  if maxByte > fileSize then
    maxByte = fileSize
  end
  local sourceFile = fs.open(filePath, "rb")
  sourceFile.seek("set", currByteCounter)
  for i=currByteCounter,maxByte do
    local byte = sourceFile.read()
    if byte then
      tapeDrive.write(byte)
    end
  end
  local percentage = math.floor((maxByte / fileSize) * 100)
  --Update screen with progress
  local progressText = string.format("Writing: %s%% complete", percentage)
  progressDisplay.updateText{text=progressText}
  screenBuffer.render()

  --Stop if done, and actually play the tape, if not, put another event in the queue
  if maxByte == fileSize then
    currentFileWrittenToTape = filePath
    progressDisplay.updateText{text=""}
    screenBuffer.render()
    rewind()
    tapeDrive.play()
    isWritingMusic = false
  else
    os.queueEvent(TAPE_WRITE_EVENT_TYPE, filePath, maxByte + 1, fileSize)
  end
  sourceFile.close()
end

function queueWrite(filePath)
  local f = fs.open(filePath, "rb")
  if f then
    local current = f.seek()
    local fileSize = f.seek("end")
    f.seek("set", current) --go back to beggining after we just went to end
    f.close()
    isWritingMusic = true
    os.queueEvent(TAPE_WRITE_EVENT_TYPE, filePath, current, fileSize)
  end
end

function rewind()
  local position = tapeDrive.getPosition()
  if position <= 0 then
    return
  end
  tapeDrive.seek(position * -1)
end

function play()
  if not isWritingMusic then
    local fileName = radioGroup.getSelected().getId()
    if fileName then
      
      if currentFileWrittenToTape == fileName then
        --resume if we are already loaded
        tapeDrive.play()
      else
        --if we are not loaded, write the new song
        tapeDrive.stop()
        rewind()
        queueWrite(fileName)
      end
    else
      error("file doesn't exist. plz fix.")
    end
  end
end

function stop()
  if not isWritingMusic then
    tapeDrive.stop()
  end
end

getAllMusicAndCreateButtons(radioGroup)

screenBuffer.ln()
local playButton = Button.create{
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLeft,
  eventHandler=eventHandler, 
  text=" Play ", 
  textColor=colors.white, 
  bgColor=colors.green,
  leftClickCallback=play
}

local stopButton = Button.create{
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeRight,
  eventHandler=eventHandler, 
  text=" Stop ", 
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=stop
}

progressDisplay = ScreenContent.create{
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeCenter,
  text="",
}

screenBuffer.render()
eventHandler.addHandle(TAPE_WRITE_EVENT_TYPE, writeTapeUnit)

--Loops until exit handle quits it
eventHandler.pullEvents()