os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")
os.loadAPI("/gitlib/carlos/inventory.lua")

local protocol = "warehouse"



local function connect()
    local server = rednet.lookup(protocol, "warehouse_host")
    while not server do
        print("Can't connect to warehouse server, trying again")
        sleep(5)
        server = rednet.lookup(protocol)
    end
    return server
end

function get_deposit_chest(item_name)
    modem.openModems()

    local server = connect()

    while true do
        local request = {}
        request["type"] = "get_deposit_chest"
        request["item"] = item_name   

        rednet.send(server, textutils.serializeJSON(request), protocol)

        local server_id, message = rednet.receive(protocol, 5)
        if server_id then
            local response = textutils.unserializeJSON(message)
            modem.closeModems()
            return response
        end
    end    
end
