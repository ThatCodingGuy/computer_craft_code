--Event Handling library that allows the listening of multiple different os.pullEvent at the same time
--callback functions must take the table of arguments passed by os.pullEvent as a parameter
--view olivier/quotes.lua as an example of usage

local eventHandler = {}

local function create()
  local self = {
    eventTypeToCallbackData={}
  }

  local getCallbacks = function(eventType)
    local callbacks = self.eventTypeToCallbackData[eventType]
    if callbacks == nil then
      callbacks = {}
      self.eventTypeToCallbackData[eventType] = callbacks
    end
    return callbacks
  end

  local addAnyHandle = function(eventType, callback, id, clearOnHandle)
    local callbacks = getCallbacks(eventType)
    for _,value in pairs(callbacks) do
      if id ~= nil and value.id == id then
        error("id: \"" .. id .. "\" has already been passed to the event handler")
      end
    end
    table.insert(callbacks, {id=id, callback=callback, clearOnHandle=clearOnHandle})
  end

    --This event handler clears itself from the callback list after processed once
  local addOneTimeHandle = function(eventType, callback, id)
    return addAnyHandle(eventType, callback, id, true)
  end

    --add an event handler for a certain type
  local addHandle = function(eventType, callback, id)
    return addAnyHandle(eventType, callback, id, false)
  end

  local removeHandle = function(eventType, id)
    local callbacks = getCallbacks(eventType)
    for index,value in pairs(callbacks) do
      if value.id == id then
        return table.remove(callbacks, index)
      end
    end
  end

  local pullEvent = function()
    local eventData = {os.pullEvent()}
    local callbacks = getCallbacks(eventData[1])
    for index,value in pairs(callbacks) do
      value.callback(eventData)
      if value.clearOnHandle then
        table.remove(callbacks, index)
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