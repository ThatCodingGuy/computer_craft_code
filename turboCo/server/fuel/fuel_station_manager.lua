local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local modem = dofile("./gitlib/turboCo/modem.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local ObservableValue = dofile("./gitlib/turboCo/observable_value.lua")
local RecurringTask = dofile("./gitlib/turboCo/recurring_task.lua")
local FuelCoordParser = dofile("./gitlib/turboCo/server/fuel/fuel_coord_parser.lua")
local FuelStationGroup = dofile("./gitlib/turboCo/server/fuel/fuel_station_group.lua")

Logger.log_level_filter = Logger.LoggingLevel.INFO
local logger = Logger.new()
local fuel_station_coordinate_file_name = arg[1]

if fuel_station_coordinate_file_name == nil then
    logger.error("Expected a file name containing the station coordinates passed as argument.")
    return
end

modem.openModems()

local protocol = "fuel_station"
rednet.host(protocol, "fuel_station_host")

local observable_station_coords = ObservableValue.new()
local stations = FuelStationGroup.new(
        80 * 64 --[[Assumes that a stack of coal/charcoal is being used to refuel.]],
        observable_station_coords)
local fuel_coord_parser = FuelCoordParser.new(fuel_station_coordinate_file_name)
local parser_task = RecurringTask.new(60, function()
    observable_station_coords.set_value(fuel_coord_parser.parse())
end, EventHandler.create())

local function fuel_request(sender_id, request)
    local nearest = stations.find_nearest(request["position"])

    if nearest then
        local response = {}
        response["status"] = "success"
        response["position"] = nearest
        stations.reserve(nearest, sender_id)
        return response
    end

    local response = {}
    response["status"] = "none_available"
    return response
end

local function fuel_done(sender_id, request)
    stations.release(sender_id)
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

function run()
    while true do
        local senderId, message = receive()
        local request = textutils.unserializeJSON(message)
        local request_type = request["type"]
        local response = router[request_type](senderId, request)
        local message = textutils.serializeJSON(response)
        rednet.send(senderId, message, protocol)
    end
end

local router = {}
router["refuel"] = fuel_request
router["refuel_done"] = fuel_done

parallel.waitForAll(parser_task.run, run)
