--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local function create(args)
  if args.screenBufferWriteFunc == nil then
    args.screenBufferWriteFunc = args.screenBuffer.write
  end

  local self = {
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    eventHandler=args.eventHandler,
    text=args.text,
    textColor=args.textColor,
    bgColor=args.bgColor,
    leftClickCallbacks={},
    rightClickCallbacks={},
    currentScreenPos= { x=0, y=0 },
    bufferCursorPos= { x=0, y=0 },
    monitorTouchKeyHandlerId = nil,
    mouseClickKeyHandlerId = nil,
  }

  local wasClicked = function(x, y)
    local maxPosX = self.currentScreenPos.x + #self.text
    return x >= self.currentScreenPos.x and x <= maxPosX and y == self.currentScreenPos.y
  end

  local executeLeftCLickCallbacks = function()
    for _,callback in pairs(self.leftClickCallbacks) do
      callback()
    end
  end

  local executeRightClickCallbacks = function()
    for _,callback in pairs(self.rightClickCallbacks) do
      callback()
    end
  end

  local monitorTouchHandler = function(eventData)
    local x, y = eventData[3], eventData[4]
    if wasClicked(x, y) then
      executeLeftCLickCallbacks()
    end
  end

  local mouseClickHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if wasClicked(x, y) then
      if button == 1 then
        executeLeftCLickCallbacks()
      elseif button == 2 then
        executeRightClickCallbacks()
      end
    end
  end
  
  local screenBufferCallback = function(callbackData)
    self.currentScreenPos.x = self.currentScreenPos.x + callbackData.movementOffset.x
    self.currentScreenPos.y = self.currentScreenPos.y + callbackData.movementOffset.y
  end

  local isActive = function()
    return self.monitorTouchKeyHandlerId ~= nil
  end

  local makeActive = function()
    --Can assume both input method IDs to be in same state
    if not isActive() then
      self.monitorTouchKeyHandlerId = self.eventHandler.addHandle("monitor_touch", monitorTouchHandler)
      self.mouseClickKeyHandlerId = self.eventHandler.addHandle("mouse_click", mouseClickHandler)
    end
  end

  local makeInactive = function()
    --Can assume both input method IDs to be in same state
    if isActive() then
      self.eventHandler.removeHandle(self.monitorTouchKeyHandlerId)
      self.eventHandler.removeHandle(self.mouseClickKeyHandlerId)
      self.monitorTouchKeyHandlerId = nil
      self.mouseClickKeyHandlerId = nil
    end
  end

  local addLeftClickCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.leftClickCallbacks, callbackFunc)
    end
  end

  local addRightClickCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.rightClickCallbacks, callbackFunc)
    end
  end

  local updateText = function(args)
    self.text = args.text or self.text
    self.textColor = args.textColor or self.textColor
    self.bgColor = args.bgColor or self.bgColor

    self.screenBuffer.write{text=self.text, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.bufferCursorPos}
    if isActive() then
      self.screenBuffer.render()
    end
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor}
  self.currentScreenPos = writeData.screenCursorPosBefore
  self.bufferCursorPos = writeData.bufferCursorPosBefore

  if args.leftClickCallback ~= nil then
    addLeftClickCallback(args.leftClickCallback)
  end

  if args.rightClickCallback ~= nil then
    addRightClickCallback(args.rightClickCallback)
  end

  self.screenBuffer.registerCallback(screenBufferCallback)
  makeActive()

  return {
    addLeftClickCallback=addLeftClickCallback,
    addRightClickCallback=getRightClickCallback,
    makeActive=makeActive,
    makeInactive=makeInactive,
    updateText=updateText
  }

end

return {
  create = create
}