local View = dofile("./gitlib/turboCo/ui/view.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local Clickable = dofile("./gitlib/turboCo/ui/clickable.lua")
local logger = dofile("./gitlib/turboCo/logger.lua").new()

local function createFromViews(args)
  local self = {
    viewGroups = args.viewGroups,
    eventHandler = args.eventHandler,
    titleView = args.titleView,
    mainView = args.mainView,
    title = args.title,
    draggable = args.draggable,
    closeable = args.closeable
  }

  local closeWindow = function()
    self.viewGroups.removeGroup("window")
  end

  local windowDragged = function(args)
    local offsetX, offsetY = args.newScreenPos.x - args.oldScreenPos.x, args.newScreenPos.y - args.oldScreenPos.y
    self.titleView.moveBy(offsetX, offsetY)
    self.mainView.moveBy(offsetX, offsetY)
  end

  local clickableText = ""
  for i=1, self.titleView.screenBuffer.getWidth() - 1 do
    clickableText = clickableText .. " "
  end

  self.titleView.addClickable(
    Clickable.create{
      screenBuffer=self.titleView.screenBuffer,
      screenBufferWriteFunc=self.titleView.screenBuffer.writeLeft,
      eventHandler=args.eventHandler,
      text=clickableText,
      bgColor=colors.blue,
      leftMouseDragCallback=windowDragged
    }
  )

  self.titleView.addClickable(
    Button.create{
      screenBuffer=self.titleView.screenBuffer,
      screenBufferWriteFunc=self.titleView.screenBuffer.writeRight,
      eventHandler=self.eventHandler,
      text="x",
      textColor=colors.white,
      bgColor=colors.red,
      leftClickCallback=closeWindow
    }
  )

  local makeActive = function()
    self.titleView.makeActive()
    self.mainView.makeActive()
  end

  local makeInactive = function()
    self.titleView.makeInactive()
    self.mainView.makeInactive()
  end

  local windowView = {
    screenBuffer=self.mainView.screenBuffer,
    makeActive=makeActive,
    makeInactive=makeInactive
  }
  self.viewGroups.addView({groupName="window", view=windowView})
  self.viewGroups.moveGroupToTop("window")
  return windowView

end

local function create(args)
  local self = {
    view = args.view,
    title = args.title,
    draggable = args.draggable,
    closeable = args.closeable
  }
end

local function createFromOverrides(args)
  local screen, eventHandler, viewGroups, textColor, bgColor, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.eventHandler, args.viewGroups, args.textColor, args.bgColor, args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
  local _,height = screen.getSize()

  local titleView = View.createFromOverrides{
    screen=screen,
    eventHandler=eventHandler,
    textColor=textColor,
    bgColor=bgColor,
    leftOffset=leftOffset,
    rightOffset=rightOffset,
    topOffset=topOffset,
    bottomOffset=bottomOffset + height - 1,
  }
  
  local mainView = View.createFromOverrides{
    screen=screen,
    eventHandler=eventHandler,
    textColor=textColor,
    bgColor=bgColor,
    leftOffset=leftOffset,
    rightOffset=rightOffset,
    topOffset=topOffset + 1,
    bottomOffset=bottomOffset,
  }

  return createFromViews{viewGroups=viewGroups, eventHandler=eventHandler, titleView=titleView, mainView=mainView}

end

return {
  createFromOverrides=createFromOverrides
}