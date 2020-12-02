
local function create(screenBuffer)
  local self = {
    screenBuffer=screenBuffer,
    buttons = {}
  }

  local getScreenBuffer = function()
    return self.screenBuffer
  end

  local addButton = function(button)
    table.insert(self.buttons, button)
  end

  local makeInactive = function()
    for _, button in pairs(self.buttons) do
      button.makeInactive()
    end
  end

  local makeActive = function()
    for _, button in pairs(self.buttons) do
      button.makeActive()
    end
    screenBuffer.renderScreen()
  end

  return {
    getScreenBuffer=getScreenBuffer,
    addButton=addButton,
    makeInactive=makeInactive,
    makeActive=makeActive
  }

end

return {
  create=create
}