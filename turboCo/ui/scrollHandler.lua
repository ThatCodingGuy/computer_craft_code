-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- 

local function create(args)
  local self = {
    screenBuffer = args.screenBuffer,
    eventHandler = args.eventHandler,
    keyHandlerId = nil
  }

  local handleKey = function(eventData)
    local key = eventData[2]
    local screenBuffer = self.screenBuffer
    if screenBuffer ~= nil then
      if key == keys.up then
        screenBuffer.scrollUp()
      elseif key == keys.down then
        screenBuffer.scrollDown()
      elseif key == keys.left then
        screenBuffer.scrollLeft()
      elseif key == keys.right then
        screenBuffer.scrollRight()
      elseif key == keys.pageUp then
        screenBuffer.pageUp()
      elseif key == keys.pageDown then
        screenBuffer.pageDown()
      end
    end
  end

  local changeScreenBuffer = function(screenBuffer)
    self.screenBuffer = screenBuffer
  end

  --allows the key strokes to scroll the screen
  local makeActive = function()
    if self.keyHandlerId == nil then
      self.keyHandlerId = self.eventHandler.addHandle("key", handleKey)
    end
  end

  --disallows the key strokes to scroll the screen
  local makeInactive = function()
    if self.keyHandlerId ~= nil then
      self.eventHandler.remove(self.keyHandlerId)
      self.keyHandlerId = nil
    end
  end

  return {
    changeScreenBuffer=changeScreenBuffer,
    makeActive=makeActive,
    makeInactive=makeInactive,
  }
end

return {
  create=create
}