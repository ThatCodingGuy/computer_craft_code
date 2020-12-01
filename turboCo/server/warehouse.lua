os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")

modem.openModems()

-- There are many roles in the warehouse.
--
-- Warehouse server: Keeps the master record of item counts in each chest
-- Dropers: Brings items from dropoff chests to storage chest.
--          Calls the deposit API
-- Pickers: Brings items from storage chest to pickup chest.
--          Calls the withdrawal API



-- Tables
-- item_name -> {
--    chest_data : [{
--        position: coord, quantity: int
--    }]
-- }

local corner1 = movement.coord(-96, 63, 464)
local corner2 = movement.coord(-96, 63, 435)
local corner3 = movement.coord(-153, 63, 435)
local corner4 = movement.coord(-153, 63, 464)

local max_y = 100
local min_y = 63

local max_x = -96
local min_x = -153

local max_z = 464
local min_z = 435

local chest_chest = movement.coord(-94, 63, 445)

local data
if fs.exists("/db") then
    local db = fs.open("/db", r)
    local raw_data = db.readAll()
    data = textutils.unserializeJSON(raw_data)
else
    data = {}
end

local chest_spots = {}
for y = min_y, max_y, 1 do
    for x = min_x, max_x, 1 do
        for z = min_z, max_z, 1 do
            local spot = movement.coord(x, y, z)
            if x % 2 == 0 and z % 2 == 0 then
                chest_spots[spot] = 0
            end
        end
    end
end


for item_name, storage_data in pairs(data) do
    for i = 1, #storage_data["chests"], 1 do
        local spot = storage_data["chests"][i]["position"]
        chest_spots[spot] = 1
    end
end

local function save_db()
    local db = fs.open("/db", w)
    local raw_data = textutils.serializeJSON(data)
    db.write(raw_data)
end

local function get_next_chest_spot()
    local shortest_distance = 9999999999
    local best_spot = nil
    for position, is_taken in pairs(chest_spots) do
        if is_taken == 0 then
            local distance = movement.distance(chest_chest, position)
            if distance < shortest_distance then
                print(distance)
                best_spot = position
            end
        end
    end

    return best_spot
end

local function init_item_entry(item_name)
    print("New item registered: "..item_name)
    data[item_name] = {}
    data[item_name]["chest_data"] = {}
end

local function dispatch_chest(position, item_name)
    print("Dispatching new chest to "..position)
    chest_spots[position] = 1

    local chest_data = {}
    chest_data["position"] = position
    chest_data["quantity"] = 0

    table.insert(data[item_name]["chest_data"], chest_data)

    -- TODO: Send the robot
end


function deposit(item_name, quantity)
    if not data[item_name] then
        local spot = get_next_chest_spot()
        dispatch_chest(spot, item_name)
    end

    save_db()
end

