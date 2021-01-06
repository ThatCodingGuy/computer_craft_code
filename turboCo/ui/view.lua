local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")

--[[
  All classes ending in "view" have a render(), makeActive(), and makeInactive() functions
  THis is because views can be switched in and out of a screen
]]

local function createFromScreenBuffer(args)

  local self = {
    screenBuffer=args.screenBuffer,
    clickables = {}
  }

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
    screenBuffer=self.screenBuffer,
    addClickable=addClickable,
    makeInactive=makeInactive,
    makeActive=makeActive
  }

end

local function create(args)
  local screenBuffer = ScreenBuffer.create(args)
  return createFromScreenBuffer{screenBuffer=screenBuffer}
end

local function createFromOverrides(args)
  local screenBuffer = ScreenBuffer.createFromOverrides(args)
  return createFromScreenBuffer{screenBuffer=screenBuffer}
end

return {
  create=create,
  createFromOverrides=createFromOverrides,
  createFromScreenBuffer=createFromScreenBuffer
}