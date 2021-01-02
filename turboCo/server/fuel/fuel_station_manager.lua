local json = dofile("./gitlib/turboCo/json.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local modem = dofile("./gitlib/turboCo/modem.lua")
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
    refuel = function(sender_id, request)
        return fuel_request(sender_id, request)
    end,
    refuel_done = function(sender_id, request)
        return fuel_done(sender_id, request)
    end,
}
local observable_station_coords = ObservableValue.new()
local stations = FuelStationGroup.new(
        80 * 64 --[[Assumes that a stack of coal/charcoal is being used to refuel.]],
        observable_station_coords)
local logger = Logger.new()
local clients_reserving_stations = {}

function fuel_request(sender_id, request)
    local nearest = stations.find_nearest(request["position"])

    if nearest then
        logger.info("Found nearest available fuel station.")
        local response = {}
        response["status"] = "success"
        response["position"] = nearest
        local reservation_token = stations.reserve(nearest, sender_id)
        clients_reserving_stations[sender_id] = reservation_token
        return response
    end

    logger.info("Could not find a fuel station.")
    local response = {}
    response["status"] = "none_available"
    return response
end

function fuel_done(sender_id, request)
    local response = {}
    local reservation_token = clients_reserving_stations[sender_id]
    if reservation_token == nil then
        logger.warn("Client " .. sender_id .. "declared being done refueling, but client never "
                .. "reserved a fuel station.")
        response["status"] = "failure"
    else
        stations.release(sender_id)
        response["status"] = "success"
        clients_reserving_stations[sender_id] = nil
    end
    return response
end

local function handle_request(event_data)
    local _, senderId, message, protocol = unpack(event_data)
    if senderId == nil or protocol ~= PROTOCOL then
        return
    end

    logger.debug("Processing client request:\n", message)
    local request = json.decode(message)
    local request_type = request["type"]
    logger.info("Processing request type '" .. request_type .. "'.")
    local response = router[request_type](senderId, request)
    local serialized_response = json.encode(response)
    logger.debug("Sending response to client:\n", serialized_response)
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
    if parsed_arguments.coord_file_name == nil then
        logger.error("Please specify a file name containing fuel station coordinates using the "
                .. "--coord_file_name/-f parameter.")
        return
    end

    modem.openModems()
    rednet.host(PROTOCOL, "fuel_station_host")

    local fuel_coord_parser = FuelCoordParser.new(parsed_arguments.coord_file_name)
    observable_station_coords.set_value(fuel_coord_parser.parse())
    local event_handler = EventHandler.create()
    event_handler.scheduleRecurring(function()
        observable_station_coords.set_value(fuel_coord_parser.parse())
    end, parsed_arguments.coord_refresh_period)
    event_handler.addHandle("rednet_message", handle_request)
    event_handler.pullEvents()
end

run()
