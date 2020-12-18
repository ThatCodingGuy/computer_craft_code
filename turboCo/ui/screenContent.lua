--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local function create(args)
  if args.screenBufferWriteFunc == nil then
    args.screenBufferWriteFunc = args.screenBuffer.write
  end

  local self = {
    screenBuffer=args.screenBuffer,
    screenBufferWriteFunc=args.screenBufferWriteFunc,
    currentBufferPos= { x=0, y=0 },
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
    self.screenBuffer.write{text=clearingText, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.currentBufferPos}

    self.text = args.text or self.text
    self.textColor = args.textColor or self.textColor
    self.bgColor = args.bgColor or self.bgColor

    local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.currentBufferPos}
    self.currentScreenPos = writeData.screenCursorPosBefore
    self.currentBufferPos = writeData.bufferCursorPosBefore
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor}
  self.currentScreenPos = writeData.screenCursorPosBefore
  self.currentBufferPos = writeData.bufferCursorPosBefore

  return {
    updateText=updateText
  }

end

return {
  create = create
}