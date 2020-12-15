
function write(tapeDrive, tArgs)
  if tArgs ~= 2 then
    print("Usage: tape write <path_to_file>")
    return
  end
  local f = fs.open(tArgs[2], "rb")
  local byte
  repeat
    byte = f.read()
    if byte then drive.write(byte) end
  until not byte
  f.close()
end

function play(tapeDrive, tArgs)
  tapeDrive.play()
end

function rewind(tapeDrive, tArgs)
  local position = tapeDrive.getPosition()
  if position <= 0 then
    print("tape is already rewinded")
    return
  end
  tapeDrive.seek(position * -1)
end

function stop(tapeDrive, tArgs)
  tapeDrive.stop()
end

function getLabel(tapeDrive, tArgs)
  tapeDrive.getLabel()
end

function setLabel(tapeDrive, tArgs)
  if tArgs ~= 2 then
    print("Usage: tape setLabel <label_name>")
    return
  end
  tapeDrive.setLabel(tArgs[2])
end

local commands = {
  write=write,
  play=play,
  rewind=rewind,
  stop=stop,
  setLabel=setLabel,
  getLabel=getLabel
}

local tArgs = { ... }

if #tArgs < 1 then
  print("Usage: tape <command>")
  print("Possible commands are ['write', rewind', 'play', 'stop', 'getLabel', 'setLabel']")
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
  print("Possible commands are ['write', rewind', 'play', 'stop', 'getLabel', 'setLabel']")
end
