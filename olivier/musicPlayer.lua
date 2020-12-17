local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")

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
  [5]="/gitlib/olivier/music/dangerZone.dfpwm"
}

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
    tape.rewind(tapeDrive)
  end
  tapeDrive.play()
end

function stop()
  tapeDrive.stop()
end

radioGroup.addRadioInput(RadioInput.create{
  id=1,
  title="Doom",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=2,
  title="Let It Snow",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=3,
  title="Mario",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=4,
  title="Megalovania",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=5,
  title="Danger Zone",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

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