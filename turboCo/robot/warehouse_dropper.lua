os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")
os.loadAPI("/gitlib/turboCo/client/warehouse.lua")

local chest_chest = movement.coord(-94, 63, 445)
local chest_pickup = movement.coord(-94, 63, 445)

local dropoff_chests = {}
dropoff_chests[movement.coord(-94, 64, 438)] = movement.coord(-95, 64, 438)
dropoff_chests[movement.coord(-94, 64, 439)] = movement.coord(-95, 64, 439)
dropoff_chests[movement.coord(-94, 64, 440)] = movement.coord(-95, 64, 440)

local function load_up_chests(facing, position)
    local item = turtle.getItemDetail(1)

    if not item then
        facing, position = movement.navigate(position, facing, chest_pickup)
        turtle.select(1)
        turtle.suckDown(32)
        return facing, position
    else
        if item.name ~= "minecraft:chest" then
            error("no chest in slot 1")
        end

        if item.count < 16 then
            facing, position = movement.navigate(position, facing, chest_pickup)
            turtle.select(1)
            turtle.suckDown(32)
            return facing, position
        end
    end

    return facing, position
end


local function wait_for_deposit()
    -- TODO: Check all chests
    turtle.select(2) -- 1 is reserved for chests
    
    while true do
        local result = turtle.suck()
        if result then break end
    end

    sleep(5)

    while true do
        local result = turtle.suck()
        if not result then break end
    end
end



local function deposit_inventory(facing, position)
    for i = 2, 16, 1 do
        local item = turtle.getItemDetail(i)

        if item then
            local name = item.name
            local count = item.count

            local response = warehouse.get_deposit_chest(name)

            local position = response["position"]
            local px, py, pz = movement.split_coord(position)
            local target = movement.coord(x+1, )


        end
    end
end

local function run()
    local position = movement.gps_locate()
    local facing = movement.figure_out_facing()

    -- Precondition
    -- Have chests
    facing, position = load_up_chests(facing, position)

    -- First, go deposit any stuff
    facing, position = deposit_inventory(facing, position)

    -- Then, go wait at chests.
    wait_for_deposit()
end