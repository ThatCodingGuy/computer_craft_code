-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- The intention is to create commonly used utility functions that computercraft does not provide

local lua_helpers = require("turboCo.lua_helpers")

local ScreenBuffer = {}

local function create(screen, xPos, yPos, width, height)

end
  local screenBuffer = ScreenBuffer:new(
    function(self)
      self.screen = screen
      self.xPos = xPos
      self.yPos = yPos
      self.width = width
      self.height = height
    end
  )
end

function ScreenBuffer.createFullScreen(screen)
  local width,height = screen.getSize()
  return ScreenBuffer.create(screen, 1, 1, width, height)
end

local function getScreenBuffer(screen)
  local screenData = screenDataMap[screen]
  if screenData == nil then
    screenData = {}
    screenDataMap[screen] = screenData
    screenData['buffer'] = {}
    screenData['coords'] = { row=1, col=1 }
  end
  return screenData
end

local function getBuffer(screen)
  local screenData = getScreenData(screen)
  return screenData['buffer']
end

local function getBufferLength(buffer)
  local lastIndex = nil
  for index,value in pairs(buffer) do
    lastIndex = index
  end
  return lastIndex
end

local function getScreenCoords(screen)
  local screenData = getScreenData(screen)
  local coords = screenData['coords']
  return coords.row, coords.col
end

local function setScreenRow(screen, row)
  local screenData = getScreenData(screen)
  local coords = screenData['coords']
  coords.row = row
end

local function setScreenCol(screen, col)
  local screenData = getScreenData(screen)
  local coords = screenData['coords']
  coords.col = col
end

local function shiftScreenCoordsLeft(screen)
  local row, col = getScreenCoords(screen)
  if col > 1 then
    setScreenCol(screen, col - 1)
  end
end

local function shiftScreenCoordsRight(screen)
  local row, col = getScreenCoords(screen)
  setScreenCol(screen, col + 1)
end

local function shiftScreenCoordsUp(screen)
  local row, col = getScreenCoords(screen)
  if row > 1 then
    setScreenRow(screen, row - 1)
  end
end

local function shiftScreenCoordsDown(screen)
  local row, col = getScreenCoords(screen)
  if row < getBufferLength(getBuffer(screen)) then
    setScreenRow(screen, row + 1)
  end
end

-- Clears the screen then resets the cursor pointer
function ScreenBuffer.clear(screen)
  screen.clear()
  screen.setCursorPos(1,1)
  screenDataMap[screen] = nil
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

--sets monitor to new color and returns the old color
local function setMonitorColorIfNeeded(screen, color)
  if color ~= nil and screen.isColor() then
    currentColor = screen.getTextColor()
    screen.setTextColor(color)
    return currentColor
  end
  return nil
end

local function screenWrite(screen, text, color)
  local oldColor = setMonitorColorIfNeeded(screen, color)
  screen.write(text)
  setMonitorColorIfNeeded(screen, oldColor)
end

local function writeCharFromBuffer(screen, buffer, row, col)
  local bufferCharData = buffer[row][col]
  screenWrite(screen, bufferCharData.char, bufferCharData.color)
end


local function renderScreen(screenBuffer)
  local width,height = screen.getSize()
  local buffer = getBuffer(screen)
  local startRow, startCol = getScreenCoords(screen)
  local maxCol = startCol+width-1
  local maxHeight = startRow+height-1
  local bufferLength = getBufferLength(buffer)
  if maxHeight > bufferLength then
   maxHeight = bufferLength
  end
  screen.clear()
  local cursorY = 1
  for i=startRow,maxHeight do
    if buffer[i] ~= nil then
      local cursorX = 1
      for j=startCol,maxCol do
        if buffer[i][j] ~= nil then
          screen.setCursorPos(cursorX, cursorY)
          writeCharFromBuffer(screen, buffer, i, j)
        end
        cursorX = cursorX + 1
      end
    end
    cursorY = cursorY + 1
  end
end

-- This function assumes that there does not need to be text wrapping
-- Text wrapping should be handled by write() function
local function writeNewTextToScreenOnRow(screen, text, color)
  local buffer = getBuffer(screen)
  local x,y = screen.getCursorPos()
  local row = buffer[y]
  if row == nil then
    row = {}
    buffer[y] = row
  end
  local charPosX = nil
  for i=1,#text do
    charPosX = x + i - 1
    row[charPosX] = { color=color, char=safeSubstring(text, i, i)}
  end
  screenWrite(screen, text, color)
end

local function setCursorToNextLine(screen)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y+1)
end

--Assuming that you have only one monitor peripheral, returns the only one
function getInstance()
  return peripheral.find("monitor")
end

--Sets cursor to the beggining of the next line
function ScreenBuffer.ln(screen)
  setCursorToNextLine(screen)
end

function ScreenBuffer.write(screen, text, color)
  writeNewTextToScreenOnRow(screen, text, color)
end

--Sets cursor to the beggining of the next line after writing
function ScreenBuffer.writeLn(screen, text, color)
  write(screen, text, color)
  setCursorToNextLine(screen)
end

--Write so that the text wraps to the next line
function ScreenBuffer.writeWrap(screen, text, color)
  local width,height = screen.getSize()
  remainingText = text
  while string.len(remainingText) > 0 do
    local x,y = screen.getCursorPos()
    local remainingX = width - x + 1
    remainingLineText = safeSubstring(remainingText, 1, remainingX)
    write(screen, remainingLineText, color)
    x,y = screen.getCursorPos()
    if (x > width) then
      setCursorToNextLine(screen)
    end
    remainingText = safeSubstring(remainingText, remainingX + 1, -1)
  end
end

--Sets cursor to the beggining of the next line after writing
function ScreenBuffer.writeWrapLn(screen, text, color)
  writeWrap(screen, text, color)
  setCursorToNextLine(screen)
end

--Writes centered text for a monitor of any size
function ScreenBuffer.writeCenter(screen, text, color)
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
function ScreenBuffer.writeCenterLn(screen, text, color)
  writeCenter(screen, text, color)
  setCursorToNextLine(screen, text)
end

--Writes text to the left for a monitor of any size
function ScreenBuffer.writeLeft(screen, text, color)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y)
  write(screen, text, color)
end

--Writes text to the left for a monitor of any size, then enter a new line
function ScreenBuffer.writeLeftLn(screen, text, color)
  writeLeft(screen, text)
  setCursorToNextLine(screen)
end

--Writes text to the right for a monitor of any size
function ScreenBuffer.writeRight(screen, text, color)
  local width,height = screen.getSize()
  local x,y = screen.getCursorPos()
  local textLen = string.len(text)
  if textLen <= width then
    screen.setCursorPos(width - string.len(text)+1, y)
  end
  write(screen, text, color)
end

--Writes text to the right for a monitor of any size, then enter a new line
function ScreenBuffer.writeRightLn(screen, text, color)
  writeRight(screen, text, color)
  setCursorToNextLine(screen)
end

function ScreenBuffer.scrollUp(screen)
  shiftScreenCoordsUp(screen)
  renderScreen(screen)
end

function ScreenBuffer.scrollDown(screen)
  shiftScreenCoordsDown(screen)
  renderScreen(screen)
end

function ScreenBuffer.scrollLeft(screen)
  shiftScreenCoordsLeft(screen)
  renderScreen(screen)
end

function ScreenBuffer.scrollRight(screen)
  shiftScreenCoordsRight(screen)
  renderScreen(screen)
end

function ScreenBuffer.pageUp(screen)
  local width,height = screen.getSize()
  for i=1,height do
    shiftScreenCoordsUp(screen)
  end
  renderScreen(screen)
end

function ScreenBuffer.pageDown(screen)
  local width,height = screen.getSize()
  for i=1,height do
    shiftScreenCoordsDown(screen)
  end
  renderScreen(screen)
end

function ScreenBuffer.pageLeft(screen)
  local width,height = screen.getSize()
  for i=1,width do
    shiftScreenCoordsLeft(screen)
  end
  renderScreen(screen)
end

function ScreenBuffer.pageRight(screen)
  local width,height = screen.getSize()
  for i=1,width do
    shiftScreenCoordsRight(screen)
  end
  renderScreen(screen)
end

return ScreenBuffer