local modem = dofile("./gitlib/turboCo/modem.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local common_argument_parsers = dofile("./gitlib/turboCo/app/common_argument_parsers.lua")
local common_argument_definitions = dofile("./gitlib/turboCo/app/common_argument_definitions.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local ObservableValue = dofile("./gitlib/turboCo/observable_value.lua")
local FuelCoordParser = dofile("./gitlib/turboCo/server/fuel/fuel_coord_parser.lua")
local FuelStationGroup = dofile("./gitlib/turboCo/server/fuel/fuel_station_group.lua")

local number_def = common_argument_definitions.number_def

local PROTOCOL = "fuel_station"

local fuel_request
local fuel_done
local router = {
    refuel = fuel_request,
    refuel_done = fuel_done,
}
local observable_station_coords = ObservableValue.new()
local stations = FuelStationGroup.new(
        80 * 64 --[[Assumes that a stack of coal/charcoal is being used to refuel.]],
        observable_station_coords)

function fuel_request(sender_id, request)
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

function fuel_done(sender_id, request)
    stations.release(sender_id)
    local response = {}
    response["status"] = "success"
    return response
end

local function handle_request(event_data)
    local _, senderId, message, protocol = unpack(event_data)
    if senderId == nil or protocol ~= PROTOCOL then
        return
    end

    local request = textutils.unserializeJSON(message)
    local request_type = request["type"]
    local response = router[request_type](senderId, request)
    local serialized_response = textutils.serializeJSON(response)
    rednet.send(senderId, serialized_response, PROTOCOL)
end

function run()
    local argument_parser = common_argument_parsers.default_parser {
        {
            long_name = "coord_file_name",
            short_name = "f",
            description = "The name of the file containing the fuel station coordinates. This file "
                    .. "will be read periodically to keep the server's in-memory coordinates up to "
                    .. "date. This argument is required.",
        },
        number_def {
            long_name = "coord_refresh_period",
            short_name = "r",
            description = "The amount of time, in seconds, to wait before reloading the coordinate "
                    .. "file. The default is 60 seconds.",
            default = 60,
        },
    }
    local parsed_arguments = argument_parser.parse(arg)
    local logger = Logger.new()
    if parsed_arguments.coord_file_name == nil then
        logger.error("Please specify a file name containing fuel station coordinates using the "
                .. "--coord_file_name/-f parameter.")
        return
    end

    modem.openModems()
    rednet.host(PROTOCOL, "fuel_station_host")

    local fuel_coord_parser = FuelCoordParser.new(parsed_arguments.coord_file_name)
    local event_handler = EventHandler.create()
    event_handler.scheduleRecurring(function()
        observable_station_coords.set_value(fuel_coord_parser.parse())
    end, parsed_arguments.coord_refresh_period)
    event_handler.addHandle("rednet_message", handle_request)
    event_handler.pullEvents()
end

run()
