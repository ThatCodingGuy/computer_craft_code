os.loadAPI("./gitlib/turboCo/json.lua")
os.loadAPI("./gitlib/turboCo/monitor.lua")

function getQuoteOfTheDay()
  local quoteResponse = http.get("https://interactive-cv-api.herokuapp.com/quotes/today", {["Content-Type"] = "application/json"})
  local responseStr = quoteResponse.readAll()
  if responseStr ~= nil then
     local responseObject = json.decode(responseStr)
     if responseObject ~= nil then
      return responseObject['quote']
     end
  end
end

function setMonitorScale(screen)
  local width,height = screen.getSize()
  monitor.setScale()
end

function getQuoteAndDisplay(screen)
  local quote = getQuoteOfTheDay()
  local screen = monitor.getInstance()
  monitor.clear(screen)
  monitor.writeCenterLn(screen, "TurboCo Motivational Billboard")
  monitor.ln(screen)
  monitor.writeCenterLn(screen, quote['title'])
  monitor.ln(screen)
  monitor.writeLn(screen, quote['content'])
  monitor.ln(screen)
  monitor.writeLeftLn(screen, "Author: " .. quote['author'])
  monitor.writeLeftLn(screen, "Date: " .. quote['date'])
end

while true do
  getQuoteAndDisplay()
  sleep(3600) --Update once an hour
end






