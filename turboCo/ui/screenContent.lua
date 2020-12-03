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

  local updateText = function(text)
    self.screenBuffer.write{text=text, color=textColor, bgColor=bgColor, bufferCursorPos=self.currentBufferPos}
    self.screenBuffer.render()
  end

  local writeData = self.screenBufferWriteFunc{text=self.text, color=self.textColor, bgColor=self.bgColor}
  self.currentBufferPos = writeData.bufferCursorPosBefore
  self.screenBuffer.registerCallback(screenBufferCallback)

  return {
    updateText=updateText,
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create = create
}