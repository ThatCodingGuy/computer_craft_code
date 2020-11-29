os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")

modem.openModems()

local protocol = "fuel_station"
rednet.host(protocol, "fuel_station_host")

local stations = {}
stations[movement.coord(-91, 73, 400)] = 0
stations[movement.coord(-92, 73, 400)] = 0
stations[movement.coord(-93, 73, 400)] = 0

local function fuel_request(sender_id, request)
    local distance = 999999999999;
    local nearest = nil;
    for k, v in pairs(stations) do
        if v == 0 then
            local station_distance = movement.distance(k, request["position"])
            if station_distance < distance then
                print("Station distance: "..station_distance.." "..k)
                nearest = k
                distance = station_distance
            end
        end
    end

    if nearest then 
        local response = {}
        response["status"] = "success"
        response["position"] = nearest
        stations[nearest] = sender_id
        return response
    end

    local response = {}
    response["status"] = "none_available"
    return response
end

local function fuel_done(sender_id, request)

    for k, v in pairs(stations) do
        if v == sender_id then
            stations[k] = 0
        end
    end

    local response = {}
    response["status"] = "success"
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
router["refuel_done"] = fuel_done

while true do
    local senderId, message = receive()
    local request = textutils.unserializeJSON(message)
    local request_type = request["type"]
    local response = router[request_type](senderId, request)
    local message = textutils.serializeJSON(response)
    rednet.send(senderId, message, protocol)
end