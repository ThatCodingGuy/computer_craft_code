local lua_helpers = dofile("./gitlib/turboCo/lua_helpers.lua")

local class = lua_helpers.class

local FakeOs = class({}, function()
    local self = {
        event_queue = {},
        current_timer_id = 0,
        current_alarm = { 0 },
    }

    local function events_are_equal(event_1, event_2)
        if #event_1 ~= #event_2 then
            return false
        end

        for i = 1, #event_1 do
            if event_1[i] ~= event_2[i] then
                return false
            end
        end
        return true
    end

    local function index_of(event_data)
        for i = 1, #self.event_queue do
            local event = self.event_queue[i]
            if events_are_equal(event, event_data) then
                return i
            end
        end
        return nil
    end

    local impersonate
    local instance
    instance = {
        version = function()
        end,
        getComputerID = function()
        end,
        getComputerLabel = function()
        end,
        setComputerLabel = function(label)
        end,
        run = function(environment, programPath, arguments)
        end,
        loadAPI = function(path)
        end,
        unloadAPI = function(name)
        end,
        pullEvent = function(event)
            local removed_event
            repeat
                removed_event = table.remove(self.event_queue, 1)
            until event == nil or removed_event == nil or removed_event[1] == event
            return removed_event
        end,
        pullEventRaw = function(event)
        end,
        queueEvent = function(event, ...)
            table.insert(self.event_queue, { event, ... })
        end,
        clock = function()
        end,
        startTimer = function(timeout)
            local returned_timer_id = self.current_timer_id
            self.current_timer_id = self.current_timer_id + 1
            instance.queueEvent("timer", returned_timer_id)
            return returned_timer_id
        end,
        cancelTimer = function(timer_id)
            local event_index = index_of({ "timer", timer_id })
            if event_index ~= nil then
                table.remove(self.event_queue, event_index)
            end
        end,
        time = function()
        end,
        sleep = function(time)
        end,
        day = function()
        end,
        setAlarm = function(time)
            local returned_alarm = self.current_alarm
            self.current_alarm = { self.current_alarm[1] + 1 }
            instance.queueEvent("alarm", returned_alarm)
            return returned_alarm
        end,
        cancelAlarm = function(alarm_id)
            local event_index = index_of({ "alarm", alarm_id })
            if event_index ~= nil then
                table.remove(self.event_queue, event_index)
            end
        end,
        shutdown = function()
        end,
        reboot = function()
        end,
        impersonate = function()
            impersonate()
        end,
        event_queue = {
            index_of = index_of,
            contains = function(event_data)
                return instance.event_queue.index_of(event_data) ~= nil
            end
        },
    }

    impersonate = function()
        _G.os = instance
    end

    return instance
end)

return FakeOs
