os.loadAPI("/gitlib/turboCo/movement.lua")
os.loadAPI("/gitlib/turboCo/modem.lua")

modem.openModems()


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


