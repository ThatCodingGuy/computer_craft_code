
PAPTH_PREFIX = "gitlib/louis/"
BOT_NAME = "cobblebitch"

sleep(2)
pcall(os.loadAPI, PAPTH_PREFIX .. BOT_NAME .. "/start.lua")
os.reboot()

