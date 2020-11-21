-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- The intention is to create commonly used utility functions that computercraft somehow does not provide

local function setCursorToNextLine(screen)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y+1)
end

local function safeSubstring(str, startIndex, endIndex)
  local length = string.len(str)
  if startIndex >= length then
    return ""
  end
  if endIndex > length then
    endIndex = -1
  end
  return string.sub(str, startIndex, endIndex)
end

--Assuming that you have only one monitor peripheral, returns the only one
function getInstance()
  return peripheral.find("monitor")
end

--Write so that the text wraps to the next line
function write(screen, text)
  local width,height = screen.getSize()
  remainingText = text
  while string.len(remainingText) > 0 do
    print("string.len(remainingText): " + string.len(remainingText))
    local x,y = screen.getCursorPos()
    local remainingX = width - x + 1
    remainingLineText = safeSubstring(remainingText, 1, remainingX)
    print("remainingLineText: " + remainingLineText)
    screen.write(remainingLineText)
    x,y = screen.getCursorPos()
    if (x == width) then
      print("endLine")
      setCursorToNextLine(screen)
    end
    remainingText = safeSubstring(remainingText, remainingX + 1, -1)
    print("remainingText: " + remainingLineText)
  end
end

--Sets cursor to the beggining of the next line after writing
function writeLn(screen, text)
  write(screen, text)
  setCursorToNextLine(screen)
end

--Writes centered text for a monitor of any size, then enter a new line
function writeCenterLn(screen, text)
  local width,height = screen.getSize()
  local x,y = screen.getCursorPos()
  local textSize = string.len(text)
  local emptySpace = width - textSize
  if emptySpace > 1 then
    startingX = (emptySpace / 2) + 1
    screen.setCursorPos(startingX, y)
  end
  writeLn(screen, text)
end

-- Clears the screen then resets the cursor pointer
function clear(screen)
  screen.clear()
  screen.setCursorPos(1,1)
end

