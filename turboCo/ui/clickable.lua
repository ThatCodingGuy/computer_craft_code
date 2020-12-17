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
    id=args.id,
    text=args.text,
    textColor=args.textColor,
    bgColor=args.bgColor,
    monitorTouchCallbacks={},
    leftMouseDownCallbacks={},
    leftMouseUpCallbacks={},
    rightMouseDownCallbacks={},
    rightMouseUpCallbacks={},
    currentScreenPos= { x=0, y=0 },
    bufferCursorPos= { x=0, y=0 },
    monitorTouchHandlerId = nil,
    mouseClickHanderId = nil,
    mouseUpHandlerId = nil,
    isLeftMouseHeldDown = false,
    isRightMouseHeldDown = false,
  }

  local wasClicked = function(x, y)
    local maxPosX = self.currentScreenPos.x + #self.text
    return x >= self.currentScreenPos.x and x <= maxPosX and y == self.currentScreenPos.y
  end

  local executeMonitorTouchCallbacks = function()
    for _,callback in pairs(self.monitorTouchCallbacks) do
      callback(self.id)
    end
  end

  local executeLeftMouseDownCallbacks = function()
    for _,callback in pairs(self.leftMouseDownCallbacks) do
      callback(self.id)
    end
  end

  local executeLeftMouseUpCallbacks = function()
    for _,callback in pairs(self.leftMouseUpCallbacks) do
      callback(self.id)
    end
  end

  local executeRightMouseDownCallbacks = function()
    for _,callback in pairs(self.rightMouseDownCallbacks) do
      callback(self.id)
    end
  end

  local executeRightMouseUpCallbacks = function()
    for _,callback in pairs(self.rightMouseUpCallbacks) do
      callback(self.id)
    end
  end

  local monitorTouchHandler = function(eventData)
    local x, y = eventData[3], eventData[4]
    if wasClicked(x, y) then
      executeMonitorTouchCallbacks()
    end
  end

  local mouseDownHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if wasClicked(x, y) then
      if button == 1 then
        self.isLeftMouseHeldDown = true
        executeLeftMouseDownCallbacks()
      elseif button == 2 then
        self.isRightMouseHeldDown = true
        executeRightMouseDownCallbacks()
      end
    end
  end

  local mouseUpHandler = function(eventData)
    local button, x, y = eventData[2], eventData[3], eventData[4]
    if button == 1 and self.isLeftMouseHeldDown then
      self.isLeftMouseHeldDown = false
      executeLeftMouseUpCallbacks()
    elseif button == 2 and self.isRightMouseHeldDown then
      self.isRightMouseHeldDown = false
      executeRightMouseUpCallbacks()
    end
  end
  
  local screenBufferCallback = function(callbackData)
    self.currentScreenPos.x = self.currentScreenPos.x + callbackData.movementOffset.x
    self.currentScreenPos.y = self.currentScreenPos.y + callbackData.movementOffset.y
  end

  local isActive = function()
    return self.monitorTouchHandlerId ~= nil
  end

  local makeActive = function()
    --Can assume both input method IDs to be in same state
    if not isActive() then
      self.monitorTouchHandlerId = self.eventHandler.addHandle("monitor_touch", monitorTouchHandler)
      self.mouseClickHanderId = self.eventHandler.addHandle("mouse_click", mouseClickHandler)
      self.mouseUpHandlerId = self.eventHandler.addHandle("mouse_up", mouseUpHandler)
    end
  end

  local makeInactive = function()
    --Can assume both input method IDs to be in same state
    if isActive() then
      self.eventHandler.removeHandle(self.monitorTouchHandlerId)
      self.eventHandler.removeHandle(self.mouseClickHanderId)
      self.eventHandler.removeHandle(self.mouseUpHandlerId)
      self.monitorTouchHandlerId = nil
      self.mouseClickHanderId = nil
      self.mouseUpHandlerId = nil
    end
  end

  local addMonitorTouchCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.monitorTouchCallbacks, callbackFunc)
    end
  end

  local addLeftMouseDownCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.leftMouseDownCallbacks, callbackFunc)
    end
  end

  local addLeftMouseUpCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.leftMouseUpCallbacks, callbackFunc)
    end
  end

  local addRightMouseDownCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.rightMouseDownCallbacks, callbackFunc)
    end
  end

  local addRightMouseUpCallback = function(callbackFunc)
    if callbackFunc ~= nil then
      table.insert(self.rightMouseUpCallbacks, callbackFunc)
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

  if args.monitorTouchCallback ~= nil then
    addMonitorTouchCallback(args.monitorTouchCallback)
  end

  if args.leftMouseDownCallback ~= nil then
    addLeftMouseDownCallback(args.leftMouseDownCallback)
  end

  if args.leftMouseUpCallback ~= nil then
    addLeftMouseUpCallback(args.leftMouseUpCallback)
  end

  if args.rightMouseDownCallback ~= nil then
    addRightMouseDownCallback(args.rightMouseDownCallback)
  end

  if args.rightMouseUpCallback ~= nil then
    addRightMouseUpCallback(args.rightMouseUpCallback)
  end

  self.screenBuffer.registerCallback(screenBufferCallback)
  makeActive()

  return {
    addMonitorTouchCallback=addMonitorTouchCallback,
    addLeftMouseDownCallback=addLeftMouseDownCallback,
    addLeftMouseUpCallback=addLeftMouseUpCallback,
    addRightMouseDownCallback=addRightMouseDownCallback,
    addRightMouseUpCallback=addRightMouseUpCallback,
    makeActive=makeActive,
    makeInactive=makeInactive,
    updateText=updateText
  }

end

return {
  create = create
}