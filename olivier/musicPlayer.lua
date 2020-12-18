local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
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
local eventHandler = EventHandler.create()
local screenTitleBuffer = ScreenBuffer.createFullScreenAtTopWithHeight{screen=screen, height=3, bgColor=colors.yellow, textColor=colors.white}
screenTitleBuffer.writeCenter{text="Music Player"}
screenTitleBuffer.render()

local screenBuffer = ScreenBuffer.createFullScreenFromTop{screen=screen, height=3, bgColor=colors.purple, textColor=colors.white}
local radioGroup = RadioGroup.create()
local progressDisplay = nil
local isWritingMusic = false
local currentFileWrittenToTape = nil

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

ExitHandler.createFromScreens({term.current(), screen}, eventHandler)
eventHandler.addHandle(TAPE_WRITE_EVENT_TYPE, writeTapeUnit)

--Loops until exit handle quits it
eventHandler.pullEvents()