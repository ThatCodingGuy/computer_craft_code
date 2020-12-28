--Event Handling library that allows the listening of multiple different os.pullEvent at the same time
--callback functions must take the table of arguments passed by os.pullEvent as a parameter
--view olivier/quotes.lua as an example of usage

local eventHandler = {}

local function create()
    local self = {
        callbackDataList = {},
        currId = 1,
        listening = true,
        toBeRemoved = {},
    }

    --add an event handler for a certain type
    local addHandle = function(eventType, callback)
        local handleId = self.currId
        table.insert(self.callbackDataList,
                { callback = callback, eventType = eventType, id = self.currId })
        self.currId = self.currId + 1
        return handleId
    end

    local removeHandle = function(id)
        table.insert(self.toBeRemoved, id)
    end

    -- Schedules `callback` to run in `delay` seconds.
    local schedule = function(callback, delay)
        local timerId = os.startTimer(delay)
        local handleId
        handleId = addHandle("timer", function(eventData)
            if eventData[2] == timerId then
                removeHandle(handleId)
                callback()
            end
        end)
    end

    -- Schedules `callback` to run every `delay` seconds. Returns the handler ID to allow the task
    -- to be stopped by calling removeHandle.
    local scheduleRecurring = function(callback, delay)
        local timerId = os.startTimer(delay)
        return addHandle("timer", function(eventData)
            if eventData[2] == timerId then
                callback()
                timerId = os.startTimer(delay)
            end
        end)
    end

    local isListening = function()
        return self.listening
    end

    local setListening = function(listening)
        self.listening = listening
    end

    local findFirst = function(container, predicate)
        for key, value in pairs(container) do
            if predicate(value) then
                return key
            end
        end
        return nil
    end

    local pullEvents = function()
        while self.listening do
            local eventData = { os.pullEvent() }

            for index, value in pairs(self.callbackDataList) do
                local is_removed = nil ~= findFirst(self.toBeRemoved,
                        function(removed_id)
                            return value.id == removed_id
                        end)
                if value.eventType == eventData[1] and not is_removed then
                    value.callback(eventData)
                end
            end
            for _, removed_id in pairs(self.toBeRemoved) do
                local indexToRemove = findFirst(self.callbackDataList, function(callback)
                    return callback.id == removed_id
                end)
                if indexToRemove ~= nil then
                    table.remove(self.callbackDataList, indexToRemove)
                end
            end
            self.toBeRemoved = {}
        end
    end

    return {
        addHandle = addHandle,
        removeHandle = removeHandle,
        schedule = schedule,
        scheduleRecurring = scheduleRecurring,
        pullEvents = pullEvents,
        isListening = isListening,
        setListening = setListening
    }
end

eventHandler.create = create

return eventHandler