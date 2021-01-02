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
    bgColor=args.bgColor
  }

  local updateText = function(args)
    --clear old text
    local oldTextLen = #self.text
    local clearingText = ""
    for i=1,oldTextLen do
      clearingText = clearingText .. " "
    end
    self.screenBuffer.write{text=clearingText, textColor=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.currentBufferPos}

    self.text = args.text or self.text
    self.textColor = args.textColor or self.textColor
    self.bgColor = args.bgColor or self.bgColor

    local writeData = self.screenBufferWriteFunc{text=self.text, textColor=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.currentBufferPos}
    self.currentScreenPos = writeData.screenCursorPosBefore
    self.currentBufferPos = writeData.bufferCursorPosBefore

    if args.render then
      self.screenBuffer.render()
    end
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, textColor=self.textColor, bgColor=self.bgColor}
  self.currentScreenPos = writeData.screenCursorPosBefore
  self.currentBufferPos = writeData.bufferCursorPosBefore

  return {
    updateText=updateText
  }

end

return {
  create = create
}