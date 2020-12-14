--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local Clickable = dofile("./gitlib/turboCo/ui/clickable.lua")

local function create(args)

  local clickable = Clickable.create{
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    eventHandler=args.eventHandler,
    text=args.text,
    textColor=args.textColor,
    bgColor=args.bgColor,
    leftClickCallback=args.leftClickCallback,
    rightClickCallback=args.rightClickCallback,
  }

  local self = {
    clickable = clickable,
    clickTimerId = nil
  }

  local leftClick = function()
    --We want to flip the colors
    self.clickable.updateText{text=self.text, color=self.bgColor, bgColor=self.textColor, bufferCursorPos=self.bufferCursorPos}
    self.clickTimerId = os.startTimer(0.15)
  end

  local timerCallback = function(eventData)
    --we want to flip back the colors 
    if eventData[2] == self.clickTimerId then
      self.clickable.updateText{text=self.text, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.bufferCursorPos}
      self.clickTimerId = nil
    end
  end

  args.eventHandler.addHandle("timer", timerCallback)
  self.clickable.addLeftClickCallback(leftClick)
  self.clickable.makeActive()

  return {
    addLeftClickCallback=self.clickable.addLeftClickCallback,
    addRightClickCallback=self.clickable.addRightClickCallback,
    makeActive=self.clickable.makeActive,
    makeInactive=self.clickable.makeInactive
  }

end

return {
  create = create
}