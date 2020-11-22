
os.loadAPI("gitlib/turboCo/importManager.lua")
importManager.ImportRequirements("gitlib/louis/requirements")
cobblerbot.getBearings()
while (true)
do
    importManager.CheckForUpdate()
    cobblerbot.miningCycle()
end
