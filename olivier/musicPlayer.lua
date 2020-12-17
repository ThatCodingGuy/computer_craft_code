local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")

local musicFolderPath = "/gitlib/olivier/music/"
local screen = peripheral.find("monitor")
if screen == nil then
  screen = term.current()
end
local tapeDrive = peripheral.find("tape_drive")
local eventHandler = EventHandler.create()
local screenBuffer = ScreenBuffer.createFullScreen{screen=screen}
local radioGroup = RadioGroup.create()

local idMap = {
  [1]="/gitlib/olivier/music/doom.dfpwm",
  [2]="/gitlib/olivier/music/letItSnow.dfpwm",
  [3]="/gitlib/olivier/music/mario.dfpwm",
  [4]="/gitlib/olivier/music/megalovania.dfpwm",
  [5]="/gitlib/olivier/music/dangerZone.dfpwm",
  [6]="/gitlib/olivier/music/gangstasParadise.dfpwm"
}

function getAllMusicAndCreateButtons(radioGroup)
  local searchTerm = musicFolderPath .. "*.dfpwm"
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

function write(tapeDrive, filePath)
  local f = fs.open(filePath, "rb")
  if f then
    local byte
    repeat
      byte = f.read()
      if byte then tapeDrive.write(byte) end
    until not byte
    f.close()
  end
end

function rewind(tapeDrive)
  local position = tapeDrive.getPosition()
  if position <= 0 then
    return
  end
  tapeDrive.seek(position * -1)
end

function play()
  local fileName = idMap[radioGroup.getSelected().getId()]
  if fileName then
    tapeDrive.stop()
    rewind(tapeDrive)
    write(tapeDrive, fileName)
    rewind(tapeDrive)
  end
  tapeDrive.play()
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

screenBuffer.render()

local exitHandler = ExitHandler.createFromScreens({term.current(), screen}, eventHandler)

--Loops until exit handle quits it
eventHandler.pullEvents()