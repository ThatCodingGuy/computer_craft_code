-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- Basically you create a screen buffer that is meant to track a certain part of the screen (or all of it)
-- Operations such as writing and wrapping around are provided, as well as the ability to scroll through text

local screenBuffer = {}

local function create(screen, xStartingScreenPos, yStartingScreenPos, width, height)
  local self = {
    screen = screen,
    xStartingScreenPos = xStartingScreenPos,
    yStartingScreenPos = yStartingScreenPos,
    width = width,
    height = height,
    buffer={},
    coords={ row=1, col=1 },
    xCursorBufferPos = 1,
    yCursorBufferPos = 1
  }

  local resetScreenBuffer = function()
    self.buffer = {}
    self.coords = { row=1, col=1 }
  end

  local getBufferLength = function()
    local lastIndex = 0
    for index,_ in pairs(self.buffer) do
      lastIndex = index
    end
    return lastIndex
  end
  
  local shiftScreenCoordsLeft = function()
    if self.coords.col > 1 then
      self.coords.col = self.coords.col - 1
    end
  end
  
  local shiftScreenCoordsRight = function()
    self.coords.col = self.coords.col + 1
  end
  
  local shiftScreenCoordsUp = function()
    if self.coords.row > 1 then
      self.coords.row = self.coords.row - 1
    end
  end
  
  local shiftScreenCoordsDown = function()
    if self.coords.row < getBufferLength() then
      self.coords.row = self.coords.row + 1
    end
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
    local bufferCharData = self.buffer[row][col]
    screenWrite(bufferCharData.char, bufferCharData.color, bufferCharData.bgColor)
  end

  local function clearScreen()
    for y=self.yStartingScreenPos, self.height do
      for x=self.xStartingScreenPos, self.width do
        self.screen.setCursorPos(x, y)
        self.screen.write(" ")
      end
    end
  end

  local renderScreen = function()
    local maxCol = self.coords.col + self.width - 1
    local maxRow = self.coords.row + self.height - 1
    local bufferLength = getBufferLength()
    if maxRow > bufferLength then
      maxRow = bufferLength
    end
    clearScreen()
    local cursorY = self.yStartingScreenPos
    for i=self.coords.row,maxRow do
      if self.buffer[i] ~= nil then
        local cursorX = self.xStartingScreenPos
        for j=self.coords.col,maxCol do
          if self.buffer[i][j] ~= nil then
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
    local buffer = self.buffer
    local row = buffer[self.yCursorBufferPos]
    if row == nil then
      row = {}
      buffer[self.yCursorBufferPos] = row
    end
    local cursorX = self.xStartingScreenPos + self.xCursorBufferPos - 1
    local cursorY = self.yStartingScreenPos + self.yCursorBufferPos - 1
    self.screen.setCursorPos(cursorX, cursorY)

    for i=1,#text do
      local char = safeSubstring(text, i, i)
      row[self.xCursorBufferPos] = { color=color, bgColor=bgColor, char=char}
      --Making sure that we are in our buffer's space before we actually write to screen
      --If we are not, we just buffer the text without writing
      if self.yCursorBufferPos <= self.height and self.xCursorBufferPos <= self.width then
        screenWrite(char, color, bgColor)
      end
      self.xCursorBufferPos = self.xCursorBufferPos + 1
    end
  end
  
  local setCursorToNextLine = function()
    self.xCursorBufferPos = 1
    self.yCursorBufferPos = self.yCursorBufferPos + 1
  end

  -- Clears the screen for the screenBuffer then resets the cursor pointer
  local clear = function()
    resetScreenBuffer()
    clearScreen()
    renderScreen()
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
    for i=self.xCursorBufferPos,self.width do
      text = text .. char
    end
    writeLn(text, color, bgColor)
  end

    --Write so that the text wraps to the next line
  local writeWrap = function(text, color, bgColor)
    local remainingText = text
    while string.len(remainingText) > 0 do
      local remainingX = self.width - self.xCursorBufferPos + 1
      if remainingX > 1 then
        local remainingLineText = safeSubstring(remainingText, 1, remainingX)
        writeTextToBuffer(remainingLineText, color, bgColor)
      end
      if (self.xCursorBufferPos > self.width) then
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
      self.xCursorBufferPos = math.floor(emptySpace / 2) + 1
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
    self.xCursorBufferPos = 1
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
    shiftScreenCoordsUp()
    renderScreen()
  end

  local scrollDown = function()
    shiftScreenCoordsDown()
    renderScreen()
  end

  local scrollLeft = function()
    shiftScreenCoordsLeft()
    renderScreen()
  end

  local scrollRight = function()
    shiftScreenCoordsRight()
    renderScreen()
  end

  local pageUp = function()
    for i=1,self.height do
      shiftScreenCoordsUp()
    end
    renderScreen()
  end
  
  local pageDown = function()
    for i=1,self.height do
      shiftScreenCoordsDown()
    end
    renderScreen()
  end
  
  local pageLeft = function()
    for i=1,self.width do
      shiftScreenCoordsLeft()
    end
    renderScreen()
  end
  
  local pageRight = function()
    for i=1,self.width do
      shiftScreenCoordsRight()
    end
    renderScreen()
  end

  return {
    clear=clear,
    ln=ln,
    write=write,
    writeLn=writeLn,
    writeFullLineLn=writeFullLineLn,
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
    pageRight=pageRight
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
  return create(screen, 1, height-desiredHeight, width, desiredHeight)
end

local function createFullScreenFromTopAndBottom(screen, topOffset, bottomOffset)
  local width,height = screen.getSize()
  return create(screen, topOffset + 1, height-bottomOffset, width, height)
end

screenBuffer.create = create
screenBuffer.createFullScreen = createFullScreen
screenBuffer.createFullScreenAtTopWithHeight = createFullScreenAtTopWithHeight
screenBuffer.createFullScreenFromTop = createFullScreenFromTop
screenBuffer.createFullScreenAtBottomWithHeight = createFullScreenAtBottomWithHeight
screenBuffer.createFullScreenFromTopAndBottom = createFullScreenFromTopAndBottom

return screenBuffer