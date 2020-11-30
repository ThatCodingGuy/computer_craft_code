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


-- db contains a map of item label -> {
--    "storage_chests": [
--        "total": int
--        "position": coord
--    ]
-- 
-- }


local db = {}

local data
if fs.exists("/db") then
    local db = fs.open("/db", r)
    local raw_data = db.readAll()
    data = textutils.unserializeJSON(raw_data)
else
    data = {}
end


local function deposit(item_name, quantity)
    
end

