local tArgs = { ... }

if #tArgs ~= 1 then
  print("Usage: tape <path_to_file>")
  return
end

local drive = peripheral.find("tape_drive")
local f = fs.open(tArgs[1], "rb")
local byte
repeat
  byte = f.read()
  if byte then drive.write(byte) end
until not byte
f.close()