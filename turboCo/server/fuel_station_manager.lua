os.loadAPI("/gitlib/turboCo/movement.lua")

local protocol = "fuel_station"
rednet.host(protocol, "fuel_station_host")

local stations = {}
stations[movement.coord(-91, 73, 400)] = {}
stations[movement.coord(-92, 73, 400)] = {}
stations[movement.coord(-93, 73, 400)] = {}



local router = {}

while true do
    senderId, message = rednet.receive(protocol, 10)
    if not senderId then
        goto continue
    end

    print(senderId, message)

    ::continue::
end