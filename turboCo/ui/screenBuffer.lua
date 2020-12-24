--[[
  This file is intended to provide extensions to the terminal (term) API of computercraft
  Basically you create a screen buffer that is meant to track a certain part of the screen (or all of it)
  Operations such as writing and wrapping around are provided, as well as the ability to scroll through text
  Always call render() when you actually want it displayed
]]
local screenBuffer = {}

local function create(args)
  local screen, xStartingScreenPos, yStartingScreenPos, width, height, textColor, bgColor = 
        args.screen, args.xStartingScreenPos, args.yStartingScreenPos, 
        args.width, args.height, args.textColor, args.bgColor
  local self = {
    screen = screen,
    screenStartingPos = { x=xStartingScreenPos, y=yStartingScreenPos },
    width = width,
    height = height,
    textColor = textColor,
    bgColor = bgColor,
    screenState = {
      buffer={},
      renderPos={ x=1, y=1 },
      cursorPos={ x=1, y=1 }
    },
    callbacks = {}
  }

  local getScreenCursorPos = function()
    return {
      x=self.screenStartingPos.x + self.screenState.cursorPos.x - 1,
      y=self.screenStartingPos.y + self.screenState.cursorPos.y - 1,
    }
  end

  local cloneArgs = function(args)
    if args ~= nil then
      if args.bufferCursorPos ~= nil then
        args.bufferCursorPos = {
          x = args.bufferCursorPos.x,
          y = args.bufferCursorPos.y
        }
      end
    end
  end

  local getBufferLength = function()
    local lastIndex = 0
    for index,_ in pairs(self.screenState.buffer) do
      lastIndex = index
    end
    return lastIndex
  end

  local getBufferDimensions = function()
    local width = 0
    local height = 0
    for rowIndex,row in pairs(self.screenState.buffer) do
      if rowIndex > height then
        height = rowIndex
      end
      for colIndex,col in pairs(row) do
        if colIndex > width then
          width = colIndex
        end
      end
    end
    return {width=width, height=height}
  end

  local createCallbackData = function()
    return {
      movementOffset = {x=0, y=0},
      dimensions = getBufferDimensions()
    }
  end

  local sendCallbackData = function(callbackData)
    for _,callback in pairs(self.callbacks) do
      callback(callbackData)
    end
  end

  local resetScreenState = function()
    self.screenState = {
      buffer={},
      renderPos={ x=1, y=1 },
      cursorPos={ x=1, y=1 }
    }
  end

  local shiftScreenCoordsLeft = function(callbackData)
    if self.screenState.renderPos.x > 1 then
      self.screenState.renderPos.x = self.screenState.renderPos.x - 1
      callbackData.movementOffset.x = callbackData.movementOffset.x - 1
    end
    return false
  end

  local shiftScreenCoordsRight = function(callbackData)
    self.screenState.renderPos.x = self.screenState.renderPos.x + 1
    callbackData.movementOffset.x = callbackData.movementOffset.x + 1
    return true
  end

  local shiftScreenCoordsUp = function(callbackData)
    if self.screenState.renderPos.y > 1 then
      self.screenState.renderPos.y = self.screenState.renderPos.y - 1
      callbackData.movementOffset.y = callbackData.movementOffset.y - 1
      return true
    end
    return false
  end

  local shiftScreenCoordsDown = function(callbackData)
    if self.screenState.renderPos.y < getBufferLength() then
      self.screenState.renderPos.y = self.screenState.renderPos.y + 1
      callbackData.movementOffset.y = callbackData.movementOffset.y + 1
      return true
    end
    return false
  end

  local safeSubstring = function(str, startIndex, endIndex)
    local length = string.len(str)
    if startIndex > length then
      return ""
    end
    if endIndex > length then
      endIndex = -1
    end
    return string.sub(str, startIndex, endIndex)
  end

  -- This function assumes that there does not need to be text wrapping
  -- Text wrapping should be handled by writeWrap() function
  local writeTextToBuffer = function(args)
    local text, color, bgColor, bufferCursorPos = args.text, args.color, args.bgColor, args.bufferCursorPos
    if bufferCursorPos == nil then
      bufferCursorPos = {
        x=self.screenState.cursorPos.x,
        y=self.screenState.cursorPos.y
      }
    end
    local screenCursor = {
      screenCursorPosBefore = getScreenCursorPos(),
      bufferCursorPosBefore = {
        x=bufferCursorPos.x,
        y=bufferCursorPos.y
      }
    }
    local buffer = self.screenState.buffer
    local row = buffer[bufferCursorPos.y]
    if row == nil then
      row = {}
      buffer[bufferCursorPos.y] = row
    end

    for i=1,#text do
      local char = safeSubstring(text, i, i)
      row[bufferCursorPos.x] = { color=color, bgColor=bgColor, char=char}
      bufferCursorPos.x = bufferCursorPos.x + 1
    end
    --if no bufferCursorPos override is passed, then we want the cursor to be tracked
    if args.bufferCursorPos == nil then
      self.screenState.cursorPos.x = bufferCursorPos.x
      self.screenState.cursorPos.y = bufferCursorPos.y
    end
    return screenCursor
  end

  local blitMap = {
    [1]="0",
    [2]="1",
    [4]="2",
    [8]="3",
    [16]="4",
    [32]="5",
    [64]="6",
    [128]="7",
    [256]="8",
    [512]="9",
    [1024]="a",
    [2048]="b",
    [4096]="c",
    [8192]="d",
    [16384]="e",
    [32768]="f",
  }

  local getBlitTextChars = function(bufferCharData)
    local blitTextChar = " "
    if bufferCharData ~= nil and bufferCharData.char ~= nil then
      blitTextChar = bufferCharData.char
    end
    local blitColorChar = " "
    if bufferCharData ~= nil and bufferCharData.color ~= nil then
      blitColorChar = blitMap[bufferCharData.color]
    elseif self.textColor ~= nil then
      blitColorChar = blitMap[self.textColor]
    end
    local blitBgColorChar = blitMap[colors.black]
    if bufferCharData ~= nil and bufferCharData.bgColor ~= nil then
      blitBgColorChar = blitMap[bufferCharData.bgColor]
    elseif self.bgColor ~= nil then
      blitBgColorChar = blitMap[self.bgColor]
    end
    return blitTextChar, blitColorChar, blitBgColorChar
  end

  local renderEmptyRow = function(screenCursorPosX, screenCursorPosY)
    local blitText = ""
    local blitColor = ""
    local blitBgColor = ""
    for i=1,self.width do
      local blitTextChar, blitColorChar, blitBgColorChar = getBlitTextChars(nil)
      blitText = blitText .. blitTextChar
      blitColor = blitColor .. blitColorChar
      blitBgColor = blitBgColor .. blitBgColorChar
    end
    self.screen.setCursorPos(screenCursorPosX, screenCursorPosY)
    self.screen.blit(blitText, blitColor, blitBgColor)
  end

  local renderBufferRow = function(bufferRow, screenCursorPosX, screenCursorPosY)
    if bufferRow == nil then
      renderEmptyRow(screenCursorPosX, screenCursorPosY)
      return
    end
    local blitText = ""
    local blitColor = ""
    local blitBgColor = ""
    local maxCol = self.screenState.renderPos.x + self.width - 1
    for i=self.screenState.renderPos.x,maxCol do
      local bufferCharData = bufferRow[i]
      local blitTextChar, blitColorChar, blitBgColorChar = getBlitTextChars(bufferCharData)
      blitText = blitText .. blitTextChar
      blitColor = blitColor .. blitColorChar
      blitBgColor = blitBgColor .. blitBgColorChar
    end
    self.screen.setCursorPos(screenCursorPosX, screenCursorPosY)
    self.screen.blit(blitText, blitColor, blitBgColor)
  end

  local clearScreen = function()
    local maxPosY = self.screenStartingPos.y + self.height - 1
    for y=self.screenStartingPos.y, maxPosY do
      renderEmptyRow(self.screenStartingPos.x, y)
    end
  end

  local render = function()
    local maxRow = self.screenState.renderPos.y + self.height - 1
    local cursorY = self.screenStartingPos.y
    for i=self.screenState.renderPos.y,maxRow do
      renderBufferRow(self.screenState.buffer[i], self.screenStartingPos.x, cursorY)
      cursorY = cursorY + 1
    end
  end

  local setCursorToNextLine = function(args)
    --If we were providing an override to bufferCursorPos, then we do not want to set the cursor
    if args == nil or args.bufferCursorPos == nil then
      self.screenState.cursorPos.x = 1
      self.screenState.cursorPos.y = self.screenState.cursorPos.y + 1
    end
  end

  -- Clears the screen for the screenBuffer then resets the cursor pointer
  local clear = function()
    resetScreenState()
    clearScreen()
    sendCallbackData(createCallbackData())
  end

  --Sets cursor to the beggining of the next line
  local ln = function()
    setCursorToNextLine()
    sendCallbackData(createCallbackData())
  end

  local write = function(args)
    cloneArgs(args)
    local writeData = writeTextToBuffer(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --Sets cursor to the beggining of the next line after writing
  local writeLn = function(args)
    cloneArgs(args)
    local writeData = writeTextToBuffer(args)
    setCursorToNextLine(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --writes line from left to right of a single char
  local writeFullLineLn = function(args)
    cloneArgs(args)
    local char = safeSubstring(args.text, 1, 1)
    args.text = ""
    for i=self.screenState.cursorPos.x,self.width do
      args.text = args.text .. char
    end
    local writeData = writeLn(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --writes line from left to right of a single char, then set cursor to where it was
  local writeFullLineThenResetCursor = function(args)
    cloneArgs(args)
    local origX,origY = self.screenState.cursorPos.x,self.screenState.cursorPos.y
    local writeData = writeFullLineLn(args)
    self.screenState.cursorPos.x = origX
    self.screenState.cursorPos.y = origY
    sendCallbackData(createCallbackData())
    return writeData
  end

  local writeWrapImpl = function(args)
    cloneArgs(args)
    local text, color, bgColor = args.text, args.color, args.bgColor
    local remainingText = text
    local writeData = nil
    while string.len(remainingText) > 0 do
      local remainingX = self.width - self.screenState.cursorPos.x + 1
      if remainingX > 1 then
        local remainingLineText = safeSubstring(remainingText, 1, remainingX)
        local tempWriteData = writeTextToBuffer{text=remainingLineText, color=color, bgColor=bgColor}
        if writeData ~= nil then
          writeData = tempWriteData
        end
      end
      if (self.screenState.cursorPos.x > self.width) then
        setCursorToNextLine()
      end
      remainingText = safeSubstring(remainingText, remainingX + 1, -1)
    end
    return writeData
  end

  --Write so that the text wraps to the next line
  local writeWrap = function(args)
    cloneArgs(args)
    local writeData = writeWrapImpl(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --Sets cursor to the beggining of the next line after writing
  local writeWrapLn = function(args)
    cloneArgs(args)
    local writeData = writeWrapImpl(args)
    setCursorToNextLine()
    sendCallbackData(createCallbackData())
    return writeData
  end

  --Writes centered text for a monitor of any size
  local writeCenter = function(args)
    cloneArgs(args)
    local textSize = string.len(args.text)
    local emptySpace = self.width - textSize
    if emptySpace > 1 then
      local cursorPosX = math.floor(emptySpace / 2) + 1
      if args.bufferCursorPos ~= nil then
        args.bufferCursorPos.x = cursorPosX
      else
        self.screenState.cursorPos.x = cursorPosX
      end
    end
    sendCallbackData(createCallbackData())
    return writeTextToBuffer(args)
  end

    --Writes centered text for a monitor of any size, then enter a new line
  local writeCenterLn = function(args)
    cloneArgs(args)
    local writeData = writeCenter(args)
    setCursorToNextLine(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --Writes text to the left for a monitor of any size
  local writeLeft = function(args)
    cloneArgs(args)
    if args.bufferCursorPos ~= nil then
      args.bufferCursorPos.x = 1
    else
      self.screenState.cursorPos.x = 1
    end
    sendCallbackData(createCallbackData())
    return writeTextToBuffer(args)
  end

  --Writes text to the left for a monitor of any size, then enter a new line
  local writeLeftLn = function(args)
    cloneArgs(args)
    local writeData = writeLeft(args)
    setCursorToNextLine(args)
    sendCallbackData(createCallbackData())
    return writeData
  end

  --Writes text to the right for a monitor of any size
  local writeRight = function(args)
    cloneArgs(args)
    local text = args.text
    local textLen = string.len(text)
    if textLen <= self.width then
      local cursorPosX = self.width - textLen + 1
      if args.bufferCursorPos ~= nil then
        args.bufferCursorPos.x = cursorPosX
      else
        self.screenState.cursorPos.x = cursorPosX
      end
    end
    sendCallbackData(createCallbackData())
    return writeTextToBuffer(args)
  end

  --Writes text to the right for a monitor of any size, then enter a new line
  local writeRightLn = function(args)
    cloneArgs(args)
    local writeData = writeRight(args)
    setCursorToNextLine(args)
    return writeData
  end

  local scrollUp = function()
    local callbackData = createCallbackData()
    shiftScreenCoordsUp(callbackData)
    render()
    sendCallbackData(callbackData)
  end

  local scrollDown = function()
    local callbackData = createCallbackData()
    shiftScreenCoordsDown(callbackData)
    render()
    sendCallbackData(callbackData)
  end

  local scrollLeft = function()
    local callbackData = createCallbackData()
    shiftScreenCoordsLeft(callbackData)
    render()
    sendCallbackData(callbackData)
  end

  local scrollRight = function()
    local callbackData = createCallbackData()
    shiftScreenCoordsRight(callbackData)
    render()
    sendCallbackData(callbackData)
  end

  local pageUp = function()
    local callbackData = createCallbackData()
    for i=1,self.height do
      shiftScreenCoordsUp(callbackData)
    end
    render()
    sendCallbackData(callbackData)
  end

  local pageDown = function()
    local callbackData = createCallbackData()
    for i=1,self.height do
      shiftScreenCoordsDown(callbackData)
    end
    render()
    sendCallbackData(callbackData)
  end

  local pageLeft = function()
    local callbackData = createCallbackData()
    for i=1,self.width do
      shiftScreenCoordsLeft(callbackData)
    end
    render()
    sendCallbackData(callbackData)
  end

  local pageRight = function()
    local callbackData = createCallbackData()
    for i=1,self.width do
      shiftScreenCoordsRight(callbackData)
    end
    render()
    sendCallbackData(callbackData)
  end

  local registerCallback = function(callback)
    table.insert(self.callbacks, callback)
  end

  return {
    render=render,
    clear=clear,
    ln=ln,
    write=write,
    writeLn=writeLn,
    writeFullLineLn=writeFullLineLn,
    writeFullLineThenResetCursor=writeFullLineThenResetCursor,
    writeWrap=writeWrap,
    writeWrapLn=writeWrapLn,
    writeCenter=writeCenter,
    writeCenterLn=writeCenterLn,
    writeLeft=writeLeft,
    writeLeftLn=writeLeftLn,
    writeRight=writeRight,
    writeRightLn=writeRightLn,
    scrollUp=scrollUp,
    scrollDown=scrollDown,
    scrollLeft=scrollLeft,
    scrollRight=scrollRight,
    pageUp=pageUp,
    pageDown=pageDown,
    pageLeft=pageLeft,
    pageRight=pageRight,
    getScreenCursorPos=getScreenCursorPos,
    registerCallback=registerCallback
  }
end

local function createFromOverrides(args)
  local screen, leftOffset, rightOffset, topOffset, bottomOffset  = args.screen,
    args.leftOffset or 0, args.rightOffset or 0, args.topOffset or 0, args.bottomOffset or 0
  local width,height = screen.getSize()
  widthOverride = width - leftOffset - rightOffset
  heightOverride = height - topOffset - bottomOffset
  
  return create{
    screen=screen, 
    xStartingScreenPos=1 + leftOffset,
    yStartingScreenPos=1 + topOffset,
    width=widthOverride,
    height=heightOverride,
    bgColor=args.bgColor,
    textColor=args.textColor
  }
end

screenBuffer.create = create
screenBuffer.createFromOverrides = createFromOverrides

return screenBuffer