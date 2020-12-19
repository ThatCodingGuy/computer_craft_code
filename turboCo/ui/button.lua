--Creates a button on your screenBuffer
--Has monitor touch, mouse click, and mouse up handling

local Clickable = dofile("./gitlib/turboCo/ui/clickable.lua")

local function create(args)

  local clickable = Clickable.create{
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    eventHandler=args.eventHandler,
    text=args.text,
    textColor=args.textColor,
    bgColor=args.bgColor,
  }

  local self = {
    clickable = clickable,
    text = args.text,
    textColor = args.textColor,
    bgColor = args.bgColor,
    monitorClickTimerId = nil
  }

  local mouseDown = function()
    --We want to flip the colors
    self.clickable.updateText{text=self.text, textColor=self.bgColor, bgColor=self.textColor}
  end

  local mouseUp = function()
    --We want to flip back the colors to normal
    self.clickable.updateText{text=self.text, textColor=self.textColor, bgColor=self.bgColor}
  end

  local monitorTouch = function()
    --We want to flip the colors
    self.clickable.updateText{text=self.text, textColor=self.bgColor, bgColor=self.textColor}
    self.monitorClickTimerId = os.startTimer(0.05) --flip back the colors after a short time
  end

  local timerCallback = function(eventData)
    --we want to flip back the colors 
    if eventData[2] == self.monitorClickTimerId then
      self.clickable.updateText{text=self.text, textColor=self.textColor, bgColor=self.bgColor}
      self.monitorClickTimerId = nil
    end
  end

  local addLeftClickCallback = function(callback)
    self.clickable.addLeftMouseUpCallback(callback)
    self.clickable.addMonitorTouchCallback(callback)
  end

  --Button extra functionality to clickable
  self.clickable.addLeftMouseDownCallback(mouseDown)
  self.clickable.addLeftMouseUpCallback(mouseUp)
  self.clickable.addRightMouseDownCallback(mouseDown)
  self.clickable.addLeftMouseUpCallback(mouseUp)
  self.clickable.addMonitorTouchCallback(monitorTouch)
  args.eventHandler.addHandle("timer", timerCallback)

  --Adding actual requested callbacks
  if args.leftClickCallback ~= nil then
    addLeftClickCallback(args.leftClickCallback)
  end

  if args.rightClickCallback ~= nil then
    self.clickable.addRightMouseUpCallback(args.rightClickCallback)
  end

  self.clickable.makeActive()

  return {
    addLeftClickCallback=addLeftClickCallback,
    addRightClickCallback=self.clickable.addRightMouseUpCallback,
    makeActive=self.clickable.makeActive,
    makeInactive=self.clickable.makeInactive
  }

end

return {
  create = create
}