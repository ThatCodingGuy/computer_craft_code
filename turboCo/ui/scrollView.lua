-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- Basically you create a screen buffer that is meant to track a certain part of the screen (or all of it)
-- Operations such as writing and wrapping around are provided, as well as the ability to scroll through text

local function create(screenBuffer, eventHandler)
  local self = {
    screenBuffer = screenBuffer,
    eventHandler = eventHandler,
    keyHandlerId = nil
  }

  local handleKey = function(eventData)
    local key = eventData[2]
    local screenBuffer = self.screenBuffer
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

  --allows the key strokes to scroll the screen
  local makeActive = function()
    if self.keyHandlerId == nil then
      self.keyHandlerId = eventHandler.addHandle("key", handleKey)
    end
  end

  --disallows the key strokes to scroll the screen
  local makeInactive = function()
    if self.keyHandlerId ~= nil then
      eventHandler.remove(self.keyHandlerId)
    end
  end

  return {
    makeActive=makeActive,
    makeInactive=makeInactive,
  }
end

return {
  create=create
}