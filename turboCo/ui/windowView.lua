local View = dofile("./gitlib/turboCo/ui/view.lua")


local function createFromViews(args)
  local self = {
    titleView = args.titleView,
    mainView = args.mainView,
    title = args.title,
    draggable = args.draggable,
    closeable = args.closeable
  }

  

  local makeActive = function()
    self.titleView.makeActive()
    self.mainView.makeActive()
  end

  local makeInactive = function()
    self.titleView.makeInactive()
    self.mainView.makeInactive()
  end

  return {
    makeActive=makeActive,
    makeInactive=makeInactive
  }

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
  local screen, eventHandler, textColor, bgColor, leftOffset, rightOffset, topOffset, bottomOffset = args.screen,
    args.eventHandler, args.textColor, args.bgColor, args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0,args.bottomOffset or 0
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

  return createFromViews{titleView=titleView, mainView=mainView}

end

return {
  createFromOverrides=createFromOverrides
}