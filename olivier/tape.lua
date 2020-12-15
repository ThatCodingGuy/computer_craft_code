
function write(tapeDrive, tArgs)
  if #tArgs ~= 2 then
    print("Usage: tape write <path_to_file>")
    return
  end
  local filePath = tArgs[2]
  local f = fs.open(filePath, "rb")
  if f then
    local byte
    repeat
      byte = f.read()
      if byte then tapeDrive.write(byte) end
    until not byte
    f.close()
  else
    print(string.format("no file found on path %s", filePath))
  end
end

function play(tapeDrive, tArgs)
  tapeDrive.play()
  print("playing cassette")
end

function rewind(tapeDrive, tArgs)
  local position = tapeDrive.getPosition()
  if position <= 0 then
    print("tape is already rewinded")
    return
  end
  tapeDrive.seek(position * -1)
  print("tape rewinded to beginning")
end

function stop(tapeDrive, tArgs)
  tapeDrive.stop()
  print("tape stopped")
end

function getPosition(tapeDrive, tArgs)
  print(tapeDrive.getPosition())
end

function getLabel(tapeDrive, tArgs)
  print(tapeDrive.getLabel())
end

function setLabel(tapeDrive, tArgs)
  if #tArgs ~= 2 then
    print("Usage: tape setLabel <label_name>")
    return
  end
  local newLabel = tArgs[2]
  tapeDrive.setLabel(newLabel)
  print(string.format("new label set to '%s'", newLabel))
end

function setVolume(tapeDrive, tArgs)
  if #tArgs ~= 2 then
    print("Usage: tape setVolume <volume>")
    print("<volume> is a number from 0.0 to 1.0")
    return
  end
  local newVolume = tonumber(tArgs[2])
  tapeDrive.setVolume(newVolume)
  print(string.format("new volume set to '%s'", newVolume))
end

function setSpeed(tapeDrive, tArgs)
  if #tArgs ~= 2 then
    print("Usage: tape setSpeed <speed>")
    print("speed is a value from 0.25 to 2.0, denoting the difference from regular tape speed, which is 1.0.")
    return
  end
  local newSpeed = tonumber(tArgs[2])
  tapeDrive.setSpeed(newSpeed)
  print(string.format("new speed set to '%s'", newSpeed))
end

local commands = {
  write=write,
  play=play,
  rewind=rewind,
  stop=stop,
  getPosition=getPosition,
  setLabel=setLabel,
  getLabel=getLabel,
  setVolume=setVolume,
  setSpeed=setSpeed
}

local tArgs = { ... }

if #tArgs < 1 then
  print("Usage: tape <command>")
  print("Possible commands are ['write', rewind', 'play', 'stop', 'getLabel', 'setLabel', 'setVolume', 'setSpeed']")
  return
end

local drive = peripheral.find("tape_drive")
if drive == nil then
  print("no drive found")
end
local func = commands[tArgs[1]]
if func then
  func(drive, tArgs)
else
  print("Possible commands are ['write', rewind', 'play', 'stop', 'getLabel', 'setLabel', 'setVolume', 'setSpeed']")
end
