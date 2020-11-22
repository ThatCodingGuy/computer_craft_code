
os.loadAPI("gitlib/turboCo/importManager.lua")
importManager.ImportRequirements("gitlib/louis/requirements")
cobblerbot.getBearings()
local nextCheck = os.epoch("utc") + (1000*60*1)

while (true)
do
    print("**********")
    print(nextCheck)
    print(os.epoch("utc"))
    print("===========")
    if os.epoch("utc") > nextCheck then
        importManager.CheckForUpdate()
        nextCheck = os.epoch("utc") + (1000*60*1)
    end
    cobblerbot.miningCycle()
end
