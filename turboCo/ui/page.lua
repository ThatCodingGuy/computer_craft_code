local function create(args)
  local self = {
    screenBuffer=args.screenBuffer,
    clickables = args.clickables or {}
  }

  local getScreenBuffer = function()
    return self.screenBuffer
  end

  local addClickable = function(clickable)
    table.insert(self.clickables, clickable)
  end

  local makeInactive = function()
    for _, clickable in pairs(self.clickables) do
      clickable.makeInactive()
    end
  end

  local makeActive = function()
    for _, clickable in pairs(self.clickables) do
      clickable.makeActive()
    end
    self.screenBuffer.render()
  end

  return {
    getScreenBuffer=getScreenBuffer,
    addClickable=addClickable,
    makeInactive=makeInactive,
    makeActive=makeActive
  }

end

return {
  create=create
}