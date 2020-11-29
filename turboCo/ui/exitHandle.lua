
local exitHandle = {}

local function createFromScreens(screens, eventHandler)
  local self = {
    screens = screens,
    eventHandler = eventHandler,
    keyHandlerId = nil
  }

  local handleKey = function(eventData)
    local key = eventData[2]
    if key == keys['end'] then
      for _,screen in pairs(self.screens) do
        screen.clear()
        screen.setCursorPos(1,1)
      end
      eventHandler.setListening(false)
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

  self.keyHandlerId = self.eventHandler.addHandle("key", handleKey)

  return {
    makeActive=makeActive,
    makeInactive=makeInactive
  }
end

local function createFromScreen(screen, eventHandler)
  return createFromScreens( { screen }, eventHandler)
end

exitHandle.createFromScreen = createFromScreen
exitHandle.createFromScreens = createFromScreens

return exitHandle