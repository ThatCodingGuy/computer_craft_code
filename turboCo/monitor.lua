-- This file is intended to provide extensions to the terminal (term) API of computercraft
-- The intention is to create commonly used utility functions that computercraft somehow does not provide

--Sets cursor to the beggining of the next line after writing
function writeLn(screen, text)
  screen.write(text)
  local x,y = screen.getCursorPos()
  screen.setCursorPos(1, y+1)
end

--Writes centered text for a monitor of any size, then enter a new line
function writeCenterLn(screen, text)
  local width,height = screen.getSize()
  local textSize = string.len(text)
  local emptySpace = width - textSize
  if emptySpace > 1 then
    startingX = (emptySpace / 2) + 1
    screen.setCursorPos(startingX, height)
  end
  writeLn(screen, text)
end

function clear(screen)
  screen.clear()
  screen.setCursorPos(1,1)
end

