--Creates a radio input
--Has mouse hover, mouse click, and mouse

local Clickable = dofile("./gitlib/turboCo/ui/clickable.lua")

local function create(args)

  if args.id == nil then
    error("id cannot be nil for radio input.")
  end

  local self = {
    id = args.id,
    title = args.title,
    isSelected = false
  }

  local createRadioText = function()
    local checkBoxText = "[ ]"
    if self.isSelected then
      checkBoxText = "[x]"
    end
    if self.title ~= nil then
      checkBoxText = string.format("%s - %s", checkBoxText, self.title)
    end
    return checkBoxText
  end

  local clickable = Clickable.create{
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    eventHandler=args.eventHandler,
    id=args.id,
    text=createRadioText(),
    textColor=args.textColor,
    bgColor=args.bgColor,
    leftMouseDownCallback=args.leftClickCallback
  }
  self.clickable = clickable
  
  local updateTextToState = function()
    self.clickable.updateText{text=createRadioText()}
  end

  local setSelected = function(isSelected)
    self.isSelected = isSelected
    updateTextToState()
  end

  local isSelected = function()
    return self.isSelected
  end

  local getId = function()
    return self.id
  end

  local addLeftClickCallback = function(callback)
    self.clickable.addLeftMouseDownCallback(callback)
    self.clickable.addMonitorTouchCallback(callback)
  end

  self.clickable.makeActive()

  return {
    addLeftClickCallback=addLeftClickCallback,
    makeActive=self.clickable.makeActive,
    makeInactive=self.clickable.makeInactive,
    setSelected=setSelected,
    isSelected=isSelected,
    getId=getId
  }

end

return {
  create = create
}