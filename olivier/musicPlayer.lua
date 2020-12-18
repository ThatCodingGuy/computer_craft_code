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
local screenBuffer = ScreenBuffer.createFullScreen{screen=screen}
local radioGroup = RadioGroup.create()
local progressDisplay = nil

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

function playFinish()
  rewind()
  tapeDrive.play()
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
  local percentage = (maxByte / fileSize) * 100
  --Update screen with progress
  local progressText = string.format("Writing: %s/100%%", percentage)
  progressDisplay.updateText{text=progressText}
  screenBuffer.render()

  --Stop if done, and actually play the tape, if not, put another event in the queue
  if maxByte == fileSize then
    progressDisplay.updateText{text=""}
    screenBuffer.render()
    playFinish()
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
  local fileName = radioGroup.getSelected().getId()
  if fileName then
    tapeDrive.stop()
    rewind()
    queueWrite(fileName)
  else
    error("file doesn't exist. plz fix.")
  end
end

function stop()
  tapeDrive.stop()
end

getAllMusicAndCreateButtons(radioGroup)

screenBuffer.ln()
local playButton = Button.create{
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler, 
  text=" Play ", 
  textColor=colors.white, 
  bgColor=colors.green,
  leftClickCallback=play
}

screenBuffer.ln()
local stopButton = Button.create{
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler, 
  text=" Stop ", 
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=stop
}
screenBuffer.ln()

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