local lua_helpers = dofile('./gitlib/turboCo/lua_helpers.lua')
local logger = dofile('./gitlib/turboCo/logger.lua').new()

--[[
  Creates content on your screen that is tracked at a certain screen buffer location, and
  can be updated with the updateText() function. An optional screen buffer write function
  can be used making sure the intent of the content alignment is respected. For example:
  giving an screenBufferWriteFunc override of "screenBuffer.writeCenter" will make sure
  that the new text will still be centered with the updateText() command.
]]


local function create(args)
  if args.screenBufferWriteFunc == nil then
    args.screenBufferWriteFunc = args.screenBuffer.write
  end

  local self = {
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    text=args.text,
    textColor=args.textColor,
    textColors=args.textColors,
    bgColor=args.bgColor,
    bgColors=args.bgColors
  }

  local updateText = function(args)
    --clear old text
    local oldTextLen = #self.text
    local clearingText = ""
    for i=1,oldTextLen do
      clearingText = clearingText .. " "
    end
    self.screenBuffer.write{text=clearingText, textColor=self.textColor, textColors=self.textColors, bgColor=self.bgColor, bgColors=self.bgColors, bufferCursorPos=self.currentBufferPos}

    self.text = args.text or self.text
    self.textColor = args.textColor or self.textColor
    self.textColors = args.textColors or self.textColors
    self.bgColor = args.bgColor or self.bgColor
    self.bgColors = args.bgColors or self.bgColors

    logger.debug("screenContent.text: ", self.text)
    logger.debug("screenContent.textColor: ", self.textColor)
    logger.debug("screenContent.textColors: ", self.textColors)
    logger.debug("screenContent.bgColor: ", self.bgColor)
    logger.debug("screenContent.bgColors: ", self.bgColors)
    logger.debug()

    local writeData = self.screenBufferWriteFunc{text=self.text, textColor=self.textColor, textColors=self.textColors, bgColor=self.bgColor, bgColors=self.bgColors, bufferCursorPos=self.currentBufferPos}
    self.currentScreenPos = writeData.screenCursorPosBefore
    self.currentBufferPos = writeData.bufferCursorPosBefore

    if args.render then
      self.screenBuffer.render()
    end
  end

  --Only one of textColor/textColors and bgColor/bgColors should be used
  local writeData = self.screenBufferWriteFunc{text=self.text, textColor=self.textColor, textColors=self.textColors, bgColor=self.bgColor, bgColors=self.bgColors}
  self.currentScreenPos = writeData.screenCursorPosBefore
  self.currentBufferPos = writeData.bufferCursorPosBefore

  if args.render then
    self.screenBuffer.render()
  end

  return {
    updateText=updateText
  }

end

return {
  create = create
}