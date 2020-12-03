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
    screenBuffer.write{text=text, color=textColor, bgColor=bgColor, bufferCursorPos=self.currentBufferPos}
    screenBuffer.render()
  end

  local writeData = self.screenBufferWriteFunc{text=args.text, color=textColor, bgColor=backgroundColor}
  self.currentBufferPos = writeData.screenCursorPosBefore
  self.screenBuffer.registerCallback(screenBufferCallback)

  return {
    makeActive=makeActive,
    makeInactive=makeInactive
  }

end

return {
  create = create
}