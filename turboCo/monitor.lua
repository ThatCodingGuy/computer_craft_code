-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- The intention is to create commonly used utility functions that computercraft somehow does not provide

local screenToBufferMap = {}
local screenToRowMap = {}

-- Clears the screen then resets the cursor pointer
function clear(screen)
  screen.clear()
  screen.setCursorPos(1,1)
  screenToBufferMap[screen] = nil
  screenToRowMap[screen] = 1
end

local function safeSubstring(str, startIndex, endIndex)
  local length = string.len(str)
  if startIndex > length then
    return ""
  end
  if endIndex > length then
    endIndex = -1
  end
  return string.sub(str, startIndex, endIndex)
end

local function resetScreenBuffer(screen)
  local buffer = {}
  local width,height = screen.getSize()
  for i=1,height do
    local row = {}
    for j=1,width do
      row[j] = ""
    end
    table.insert(buffer, row)
  end
  screenToBufferMap[screen] = buffer
  screenToRowMap[screen] = 1
  return buffer
end


local function renderScreenFromRow(screen)
  local width,height = screen.getSize()
  local buffer = screenToBufferMap[screen]
  local startRow = screenToRowMap[screen]
  local maxHeight = startRow+height-1
  if maxHeight > #buffer then
   maxHeight = #buffer
  end
  clear(screen)
  local cursorX = 1
  local cursorY = 1
  for i=startRow,maxHeight do
    for j=1,width do
      screen.setCursorPos(cursorX, cursorY)
      screen.write(buffer[i][j])
      cursorY = cursorY + 1
    end
    cursorX = cursorX + 1
  end
end

-- This function assumes that there does not need to be text wrapping
-- Text wrapping should be handled by write() function
-- Assuming that we don't skip rows
local function writeNewTextToScreenOnRow(screen, text)
  local buffer = screenToBufferMap[screen]
  if buffer == nil then
    buffer = resetScreenBuffer(screen)
  end
  local width,height = screen.getSize()
  local x,y = screen.getCursorPos()
  local row = buffer[y]
  if row == nil then
    row = {}
    for i=1,width do
      row[i] = ""
    end
    table.insert(buffer, y, row)
  end
  local charPos = nil
  for i=1,#text do
    charPosX = x + i - 1
    row[charPosX] = safeSubstring(text, i, i)
  end
  screen.write(text)
end

local function setCursorToNextLine(screen)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y+1)
end

--sets monitor to new color and returns the old color
local function setMonitorColorIfNeeded(screen, color)
  if color ~= nil and screen.isColor() then
    currentColor = screen.getTextColor() 
    screen.setTextColor(color)
    return currentColor
  end
  return nil
end


--Assuming that you have only one monitor peripheral, returns the only one
function getInstance()
  return peripheral.find("monitor")
end

--Sets cursor to the beggining of the next line
function ln(screen)
  setCursorToNextLine(screen)
end

--Write so that the text wraps to the next line
function write(screen, text, color)
  local oldColor = setMonitorColorIfNeeded(screen, color)
  local width,height = screen.getSize()
  remainingText = text
  while string.len(remainingText) > 0 do
    local x,y = screen.getCursorPos()
    local remainingX = width - x + 1
    remainingLineText = safeSubstring(remainingText, 1, remainingX)
    writeNewTextToScreenOnRow(screen, remainingLineText)
    x,y = screen.getCursorPos()
    if (x > width) then
      setCursorToNextLine(screen)
    end
    remainingText = safeSubstring(remainingText, remainingX + 1, -1)
  end
  setMonitorColorIfNeeded(screen, oldColor)
end

--Sets cursor to the beggining of the next line after writing
function writeLn(screen, text, color)
  write(screen, text, color)
  setCursorToNextLine(screen)
end

--Writes centered text for a monitor of any size
function writeCenter(screen, text, color)
  local width,height = screen.getSize()
  local x,y = screen.getCursorPos()
  local textSize = string.len(text)
  local emptySpace = width - textSize
  if emptySpace > 1 then
    startingX = (emptySpace / 2) + 1
    screen.setCursorPos(startingX, y)
  end
  write(screen, text, color)
end

--Writes centered text for a monitor of any size, then enter a new line
function writeCenterLn(screen, text, color)
  writeCenter(screen, text, color)
  setCursorToNextLine(screen, text)
end

--Writes text to the left for a monitor of any size
function writeLeft(screen, text, color)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y)
  write(screen, text, color)
end

--Writes text to the left for a monitor of any size, then enter a new line
function writeLeftLn(screen, text, color)
  writeLeft(screen, text)
  setCursorToNextLine(screen, text, color)
end

--Writes text to the right for a monitor of any size
function writeRight(screen, text, color)
  local width,height = screen.getSize()
  local x,y = screen.getCursorPos()
  local textLen = string.len(text)
  if textLen <= width then
    screen.setCursorPos(width - string.len(text)+1, y)
  end
  write(screen, text, color)
end

--Writes text to the right for a monitor of any size, then enter a new line
function writeRightLn(screen, text, color)
  writeRight(screen, text, color)
  setCursorToNextLine(screen)
end

function scrollUp(screen)
  local currRow = screenToRowMap[screen]
  if currRow == nil then
    return
  end
  currRow = currRow - 1
  screenToRowMap[screen] = currRow
  renderScreenFromRow(screen)
end

function scrollDown(screen)
  local currRow = screenToRowMap[screen]
  if currRow == nil then
    return
  end
  currRow = currRow + 1
  screenToRowMap[screen] = currRow
  renderScreenFromRow(screen)
end

