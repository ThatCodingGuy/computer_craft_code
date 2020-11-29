os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")

modem.openModems()

local protocol = "fuel_station"
rednet.host(protocol, "fuel_station_host")

local stations = {}
stations[movement.coord(-91, 73, 400)] = {}
stations[movement.coord(-92, 73, 400)] = {}
stations[movement.coord(-93, 73, 400)] = {}

local function fuel_request(sender_id, request)
    print("Refuel request")
    print("Search near "..request["position"])

    local response = {}
    response["position"] = movement.coord(-91, 73, 400)
    return response
end

local function receive() 
    while true do
        senderId, message = rednet.receive(protocol, 10)
        if senderId then
            return senderId, message
        end
    end
end

local router = {}
router["refuel"] = fuel_request

while true do
    local senderId, message = receive()
    local request = textutils.unserialize(message)
    local request_type = request["type"]
    local response = router[request_type](senderId, request)
    local message = textutils.serialize(reponse)
    print(message)
    rednet.send(senderId, message, protocol)
end