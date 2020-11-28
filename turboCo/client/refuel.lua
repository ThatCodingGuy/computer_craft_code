
os.loadAPI("/gitlib/turboCo/movement.lua")
local protocol = "fuel_station"

local function connect()
    local server = rednet.lookup(fuel_station)
    while server == nil then
        print("Can't connect to reful server, trying again")
        sleep(5)
        server = rednet.lookup(fuel_station)
    end
    return server
end


function request_refuel(position)
    local id = os.getComputerID()
    local server = connect()

    while true do
        local request = {}
        request["type"] = "refuel"
        request["position"] = position
        

        rednet.send(server, textutils.serialize(request), protocol)

        local server_id, message = redent.receive(protocol, 5)
        if server_id then
            break
        end
    end
    
    local reponse = textutils.unserialize(response) 
    return response["position"]
end