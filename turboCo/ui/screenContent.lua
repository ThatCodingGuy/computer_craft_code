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

  local updateText = function(newText)
    self.text = newText
    self.screenBuffer.write{text=self.text, color=self.textColor, bgColor=self.bgColor, bufferCursorPos=self.currentBufferPos}
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor}
  self.currentBufferPos = writeData.bufferCursorPosBefore

  return {
    updateText=updateText
  }

end

return {
  create = create
}