-- load requirements and requirements management library
os.loadAPI("gitlib/turboCo/importManager.lua")
importManager.ImportRequirements("gitlib/louis/cobblebitch/requirements",'"gitlib/louis/cobblebitch/start.lua"')

-- Feel free to insert start up code here
cobblerbot.getBearings()

-- get unix time + 1 minute
local nextCheck = os.epoch("utc") + (1000*60*1)
while (true)
do
    -- check every minute
    if os.epoch("utc") > nextCheck then
        importManager.CheckForUpdate()
        nextCheck = os.epoch("utc") + (1000*60*1)
    end

    -- insert commands
    cobblerbot.miningCycle()
end