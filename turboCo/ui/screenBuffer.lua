-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- Basically you create a screen buffer that is meant to track a certain part of the screen (or all of it)
-- Operations such as writing and wrapping around are provided, as well as the ability to scroll through text
-- Always call renderScreen() when you actually want it displayed
local screenBuffer = {}

local function create(screen, xStartingScreenPos, yStartingScreenPos, width, height)
  local self = {
    screen = screen,
    screenStartingPos = { x=xStartingScreenPos, y=yStartingScreenPos },
    width = width,
    height = height,
    screenState = {
      buffer={},
      renderPos={ x=1, y=1 },
      cursorPos={ x=1, y=1 }
    },
    callbacks = {}
  }

  local resetScreenState = function()
    self.screenState = {
      buffer={},
      renderPos={ x=1, y=1 },
      cursorPos={ x=1, y=1 }
    }
  end

  local getBufferLength = function()
    local lastIndex = 0
    for index,_ in pairs(self.screenState.buffer) do
      lastIndex = index
    end
    return lastIndex
  end

  local shiftScreenCoordsLeft = function(movementOffset)
    if self.screenState.renderPos.x > 1 then
      self.screenState.renderPos.x = self.screenState.renderPos.x - 1
      movementOffset.x = movementOffset.x - 1
    end
    return false
  end

  local shiftScreenCoordsRight = function(movementOffset)
    self.screenState.renderPos.x = self.screenState.renderPos.x + 1
    movementOffset.x = movementOffset.x + 1
    return true
  end

  local shiftScreenCoordsUp = function(movementOffset)
    if self.screenState.renderPos.y > 1 then
      self.screenState.renderPos.y = self.screenState.renderPos.y - 1
      movementOffset.y = movementOffset.y - 1
      return true
    end
    return false
  end

  local shiftScreenCoordsDown = function(movementOffset)
    if self.screenState.renderPos.y < getBufferLength() then
      self.screenState.renderPos.y = self.screenState.renderPos.y + 1
      movementOffset.y = movementOffset.y + 1
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

    --sets monitor to new colors and returns the old colors
  local setMonitorColorIfNeeded = function(color, bgColor)
    if self.screen.isColor() then
      local currentColor = self.screen.getTextColor()
      if color ~= nil then
        self.screen.setTextColor(color)
      end
      local currentBgColor = self.screen.getBackgroundColor()
      if bgColor ~= nil then
        self.screen.setBackgroundColor(bgColor)
      end
      return currentColor, currentBgColor
    end
    return nil, nil
  end

  local screenWrite = function(text, color, bgColor)
    local oldColor, oldBgColor = setMonitorColorIfNeeded(color, bgColor)
    self.screen.write(text)
    setMonitorColorIfNeeded(oldColor, oldBgColor)
  end

  local writeCharFromBuffer = function(row, col)
    local bufferCharData = self.screenState.buffer[row][col]
    screenWrite(bufferCharData.char, bufferCharData.color, bufferCharData.bgColor)
  end

  local clearScreen = function()
    for y=self.screenStartingPos.y, self.height do
      for x=self.screenStartingPos.x, self.width do
        self.screen.setCursorPos(x, y)
        self.screen.write(" ")
      end
    end
  end

  local renderScreen = function()
    local maxCol = self.screenState.renderPos.x + self.width - 1
    local maxRow = self.screenState.renderPos.y + self.height - 1
    local bufferLength = getBufferLength()
    if maxRow > bufferLength then
      maxRow = bufferLength
    end
    clearScreen()
    local cursorY = self.screenStartingPos.y
    for i=self.screenState.renderPos.y,maxRow do
      if self.screenState.buffer[i] ~= nil then
        local cursorX = self.screenStartingPos.x
        for j=self.screenState.renderPos.x,maxCol do
          if self.screenState.buffer[i][j] ~= nil then
            self.screen.setCursorPos(cursorX, cursorY)
            writeCharFromBuffer(i, j)
          end
          cursorX = cursorX + 1
        end
      end
      cursorY = cursorY + 1
    end
  end

  -- This function assumes that there does not need to be text wrapping
  -- Text wrapping should be handled by writeWrap() function
  local writeTextToBuffer = function(text, color, bgColor)
    local buffer = self.screenState.buffer
    local row = buffer[self.screenState.cursorPos.y]
    if row == nil then
      row = {}
      buffer[self.screenState.cursorPos.y] = row
    end
    local cursorX = self.screenStartingPos.x + self.screenState.cursorPos.x - 1
    local cursorY = self.screenStartingPos.y + self.screenState.cursorPos.y - 1
    self.screen.setCursorPos(cursorX, cursorY)

    for i=1,#text do
      local char = safeSubstring(text, i, i)
      row[self.screenState.cursorPos.x] = { color=color, bgColor=bgColor, char=char}
      self.screenState.cursorPos.x = self.screenState.cursorPos.x + 1
    end
  end

  local setCursorToNextLine = function()
    self.screenState.cursorPos.x = 1
    self.screenState.cursorPos.y = self.screenState.cursorPos.y + 1
  end

  -- Clears the screen for the screenBuffer then resets the cursor pointer
  local clear = function()
    resetScreenState()
    clearScreen()
  end

  --Sets cursor to the beggining of the next line
  local ln = function()
    setCursorToNextLine()
  end

  local write = function(text, color, bgColor)
    writeTextToBuffer(text, color, bgColor)
  end

  --Sets cursor to the beggining of the next line after writing
  local writeLn = function(text, color, bgColor)
    write(text, color, bgColor)
    setCursorToNextLine()
  end

  --writes line from left to right of a single char
  local writeFullLineLn = function(text, color, bgColor)
    local char = safeSubstring(text, 1, 1)
    local text = ""
    for i=self.screenState.cursorPos.x,self.width do
      text = text .. char
    end
    writeLn(text, color, bgColor)
  end

  --writes line from left to right of a single char, then set cursor to where it was
  local writeFullLineThenResetCursor = function(text, color, bgColor)
    local origX,origY = self.screenState.cursorPos.x,self.screenState.cursorPos.y
    writeFullLineLn(text, color, bgColor)
    self.screenState.cursorPos.x = origX
    self.screenState.cursorPos.y = origY
  end

    --Write so that the text wraps to the next line
  local writeWrap = function(text, color, bgColor)
    local remainingText = text
    while string.len(remainingText) > 0 do
      local remainingX = self.width - self.screenState.cursorPos.x + 1
      if remainingX > 1 then
        local remainingLineText = safeSubstring(remainingText, 1, remainingX)
        writeTextToBuffer(remainingLineText, color, bgColor)
      end
      if (self.screenState.cursorPos.x > self.width) then
        setCursorToNextLine()
      end
      remainingText = safeSubstring(remainingText, remainingX + 1, -1)
    end
  end

  --Sets cursor to the beggining of the next line after writing
  local writeWrapLn = function(text, color, bgColor)
    writeWrap(text, color, bgColor)
    setCursorToNextLine()
  end

  --Writes centered text for a monitor of any size
  local writeCenter = function(text, color, bgColor)
    local textSize = string.len(text)
    local emptySpace = self.width - textSize
    if emptySpace > 1 then
      self.screenState.cursorPos.x = math.floor(emptySpace / 2) + 1
    end
    writeTextToBuffer(text, color, bgColor)
  end

    --Writes centered text for a monitor of any size, then enter a new line
  local writeCenterLn = function(text, color, bgColor)
    writeCenter(text, color, bgColor)
    setCursorToNextLine()
  end

  --Writes text to the left for a monitor of any size
  local writeLeft = function(text, color, bgColor)
    self.screenState.cursorPos.x = 1
    write(text, color, bgColor)
  end

  --Writes text to the left for a monitor of any size, then enter a new line
  local writeLeftLn = function(text, color, bgColor)
    writeLeft(text, color, bgColor)
    setCursorToNextLine()
  end

  --Writes text to the right for a monitor of any size
  local writeRight = function(text, color, bgColor)
    local textLen = string.len(text)
    if textLen <= self.width then
      self.xStartingPos = self.width - string.len(text)+1
    end
    write(text, color, bgColor)
  end

  --Writes text to the right for a monitor of any size, then enter a new line
  local writeRightLn = function(text, color, bgColor)
    writeRight(text, color, bgColor)
    setCursorToNextLine()
  end

  local scrollUp = function()
    local movementOffset = { x=0, y=0 }
    shiftScreenCoordsUp(movementOffset)
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local scrollDown = function()
    local movementOffset = { x=0, y=0 }
    shiftScreenCoordsDown(movementOffset)
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local scrollLeft = function()
    local movementOffset = { x=0, y=0 }
    shiftScreenCoordsLeft(movementOffset)
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local scrollRight = function()
    local movementOffset = { x=0, y=0 }
    shiftScreenCoordsRight(movementOffset)
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local pageUp = function()
    local movementOffset = { x=0, y=0 }
    for i=1,self.height do
      shiftScreenCoordsUp(movementOffset)
    end
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local pageDown = function()
    local movementOffset = { x=0, y=0 }
    for i=1,self.height do
      shiftScreenCoordsDown(movementOffset)
    end
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local pageLeft = function()
    local movementOffset = { x=0, y=0 }
    for i=1,self.width do
      shiftScreenCoordsLeft(movementOffset)
    end
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local pageRight = function()
    local movementOffset = { x=0, y=0 }
    for i=1,self.width do
      shiftScreenCoordsRight(movementOffset)
    end
    renderScreen()
    for _,callback in pairs(self.callbacks) do
      callback(movementOffset.x, movementOffset.y)
    end
  end

  local getScreenCursorPos = function()
    return self.screenStartingPos.x + self.screenState.cursorPos.x - 1,
           self.screenStartingPos.y + self.screenState.cursorPos.y - 1
  end

  local registerCallback = function(callback)
    table.insert(self.callbacks, callback)
  end

  return {
    renderScreen=renderScreen,
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

local function createFullScreen(screen)
  local width,height = screen.getSize()
  return create(screen, 1, 1, width, height)
end

local function createFullScreenAtTopWithHeight(screen, desiredHeight)
  local width,_ = screen.getSize()
  return create(screen, 1, 1, width, desiredHeight)
end

local function createFullScreenFromTop(screen, topOffset)
  local width,height = screen.getSize()
  return create(screen, 1, topOffset + 1, width, height)
end

local function createFullScreenAtBottomWithHeight(screen, desiredHeight)
  local width,height = screen.getSize()
  return create(screen, 1, height-desiredHeight+1, width, desiredHeight)
end

local function createFullScreenFromTopAndBottom(screen, topOffset, bottomOffset)
  local width,height = screen.getSize()
  return create(screen, 1, topOffset + 1, width, height-topOffset-bottomOffset)
end

screenBuffer.create = create
screenBuffer.createFullScreen = createFullScreen
screenBuffer.createFullScreenAtTopWithHeight = createFullScreenAtTopWithHeight
screenBuffer.createFullScreenFromTop = createFullScreenFromTop
screenBuffer.createFullScreenAtBottomWithHeight = createFullScreenAtBottomWithHeight
screenBuffer.createFullScreenFromTopAndBottom = createFullScreenFromTopAndBottom

return screenBuffer