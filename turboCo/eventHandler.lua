--Event Handling library that allows the listening of multiple different os.pullEvent at the same time
--callback functions must take the table of arguments passed by os.pullEvent as a parameter
--view olivier/quotes.lua as an example of usage

local eventHandler = {}

local function create()
  local self = {
    callbackDataList={},
    currId=1
  }

  local addAnyHandle = function(eventType, callback, clearOnHandle)
    local handleId = self.currId
    table.insert(self.callbackDataList, {callback=callback, eventType=eventType, id=self.currId, clearOnHandle=clearOnHandle})
    self.currId = self.currId + 1
    return handleId
  end

  --This event handler clears itself from the callback list after processed once
  local addOneTimeHandle = function(eventType, callback)
    return addAnyHandle(eventType, callback, true)
  end

    --add an event handler for a certain type
  local addHandle = function(eventType, callback)
    return addAnyHandle(eventType, callback, false)
  end

  local removeHandle = function(id)
    for index,value in pairs(self.callbackDataList) do
      if value.id == id then
        return table.remove(self.callbackDataList, index)
      end
    end
  end

  local pullEvent = function()
    local eventData = {os.pullEvent()}
    for index,value in pairs(self.callbackDataList) do
      if value.eventType == eventData[1] then
        value.callback(eventData)
        if value.clearOnHandle then
          table.remove(self.callbackDataList, index)
        end
      end
    end
  end

  return {
    addOneTimeHandle=addOneTimeHandle,
    addHandle=addHandle,
    removeHandle=removeHandle,
    pullEvent=pullEvent
  }
end

eventHandler.create = create

return eventHandler