--Event Handling library that allows the listening of multiple different os.pullEvent at the same time
--callback functions must take the table of arguments passed by os.pullEvent as a parameter
--view olivier/quotes.lua as an example of usage

local eventHandler = {}

local function create()
  local self = {
    callbackDataList={},
    currId=1,
    listening=true
  }

    --add an event handler for a certain type
  local addHandle = function(eventType, callback)
    local handleId = self.currId
    table.insert(self.callbackDataList, {callback=callback, eventType=eventType, id=self.currId })
    self.currId = self.currId + 1
    return handleId
  end

  local removeHandle = function(id)
    for index,value in pairs(self.callbackDataList) do
      if value.id == id then
        return table.remove(self.callbackDataList, index)
      end
    end
  end

  local isListening = function()
    return self.listening
  end

  local setListening = function(listening)
    self.listening = listening
  end

  local pullEvents = function()
    while self.listening do
      local eventData = {os.pullEvent()}
      for index,value in pairs(self.callbackDataList) do
        if value.eventType == eventData[1] then
          value.callback(eventData)
        end
      end
    end
  end

  return {
    addHandle=addHandle,
    removeHandle=removeHandle,
    pullEvents=pullEvents,
    isListening=isListening,
    setListening=setListening
  }
end

eventHandler.create = create

return eventHandler