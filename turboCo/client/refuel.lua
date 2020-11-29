
os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")

local protocol = "fuel_station"

local function connect()
    
    local server = rednet.lookup(protocol, "fuel_station_host")
    while not server do
        print("Can't connect to reful server, trying again")
        sleep(5)
        server = rednet.lookup(protocol)
    end
    return server
end


function request_refuel(position)
    modem.openModems()

    local id = os.getComputerID()
    local server = connect()

    while true do
        local request = {}
        request["type"] = "refuel"
        request["position"] = position
        

        rednet.send(server, textutils.serialize(request), protocol)

        local server_id, message = rednet.receive(protocol, 5)
        if server_id then
            break
        end
    end
    
    print(server_id)
    print(message)
    local reponse = textutils.unserialize(message) 
    closeModems()

    return response["position"]
end