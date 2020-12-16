local EventHandler = dofile("./gitlib/turboCo/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")

local screen = peripheral.find("monitor")
local eventHandler = EventHandler.create()
local screenBuffer = ScreenBuffer.createFullScreen{screen=screen}
local radioGroup = RadioGroup.create()

radioGroup.addRadioInput(RadioInput.create{
  id=1,
  title="Hello",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=2,
  title="Cool",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

radioGroup.addRadioInput(RadioInput.create{
  id=3,
  title="Ayo",
  screenBuffer=screenBuffer,
  screenBufferWriteFunc=screenBuffer.writeLn,
  eventHandler=eventHandler
})

screenBuffer.render()

local exitHandler = ExitHandler.createFromScreens({term.current(), screen}, eventHandler)

--Loops until exit handle quits it
eventHandler.pullEvents()