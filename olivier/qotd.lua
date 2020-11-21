os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")

function getQuoteOfTheDay()
  local quoteResponse = http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"})
  local responseStr = quoteResponse.readAll()
  if responseStr ~= nil then
     local responseObject = json.decode(responseStr)
     if responseObject ~= nil then
      responseStr.close()
      return responseObject['quote']
     end
  end
  if responseStr ~= nil then
   responseStr.close()
  end
end

local quote = getQuoteOfTheDay()
local screen = monitor.getInstance()

monitor.writeCenterLn(screen, "TurboCo Motivational Billboard")
monitor.ln(screen)
monitor.writeCenterLn(screen, quote['title'])
monitor.ln(screen)
monitor.writeLn(screen, quote['content'])
monitor.ln(screen)
monitor.writeLeft(screen, "Author: " .. quote['author'])
monitor.writeRight(screen, "Date: " .. quote['date'])




