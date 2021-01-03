local function create(args)
  local self = {
    view=args.view,
    clickables = args.clickables or {}
  }

  local getScreenBuffer = function()
    return self.view.getScreenBuffer()
  end

  local addClickable = function(clickable)
    table.insert(self.clickables, clickable)
  end

  local makeInactive = function()
    for _, clickable in pairs(self.clickables) do
      clickable.makeInactive()
    end
    self.view.makeInactive()
  end

  local makeActive = function()
    for _, clickable in pairs(self.clickables) do
      clickable.makeActive()
    end
    self.view.makeActive()
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