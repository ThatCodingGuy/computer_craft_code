-- load requirements and requirements management library
os.loadAPI("gitlib/turboCo/importManager.lua")
importManager.ImportRequirements("gitlib/louis/cobblebitch/requirements","gitlib/louis/cobblebitch/start.lua")

-- Feel free to insert start up code here
cobblerbot.getBearings()

-- get unix time + 1 minute
NEXT_CHECK = os.epoch("utc") + (1000*60*1)


function main()
    while (true)
    do
        -- check every minute
        if os.epoch("utc") > NEXT_CHECK then
            importManager.CheckForUpdate()
            NEXT_CHECK = os.epoch("utc") + (1000*60*1)
        end
    -- insert commands
    cobblerbot.miningCycle()
end
end