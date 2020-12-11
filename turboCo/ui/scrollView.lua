local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local ScrollBar = dofile("./gitlib/turboCo/ui/scrollbar.lua")

local function create(args)
  local screen, xStartingScreenPos, yStartingScreenPos, width, height, bgColor = 
        args.screen, args.xStartingScreenPos, args.yStartingScreenPos, 
        args.width, args.height, args.bgColor

  local screenBuffer = ScreenBuffer.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = width - 1,
    height = height,
    bgColor = bgColor
  }

  local scrollbar = ScrollBar.create{
    screen = screen,
    xStartingScreenPos = xStartingScreenPos + width,
    yStartingScreenPos = yStartingScreenPos,
    height = height
  }

  local self = {
    screenBuffer=screenBuffer,
    scrollbar=scrollbar
  }

  local getScreenBuffer = function()
    return self.screenBuffer
  end

  local makeActive = function()
    self.scrollbar.makeActive()
  end

  local makeInactive = function()
    self.scrollbar.makeInactive()
  end

  return {
    getScreenBuffer=getScreenBuffer,
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create=create
}