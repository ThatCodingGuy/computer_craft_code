-- Controller which aggregates stats sent to the "shear_stats" protocol on rednet and displays in a per-minute basis.
--
-- The shear_stats protocol message should be a table with the keys:
-- 
--   total_wool: int  -- total amount of wool a bot currently has.

cmdline = {...}

function log(severity, ...)
    print(severity..":t="..os.clock(), unpack(arg))
end

function vlog(...)
    for _,v in pairs(cmdline) do
        if v == "-v" then
            log("V", unpack(arg))
            return
        end
    end
end

function ilog(...)
    log("I", unpack(arg))
end

g_prev_stats_bucket = nil
g_prev_stats_time = nil

g_current_stats_bucket = {}
g_current_stats_time = nil

g_exponential_moving_average_weight = 0.7
g_exponential_moving_average = nil

function collectUpdates(secs_to_wait)
    end_time = os.clock() + secs_to_wait
    secs_left = secs_to_wait
    while secs_left > 0 do
        vlog("waiting " .. secs_left .. "s for updates")
        sender_id, message = rednet.receive("shear_stats", secs_left)
        secs_left = end_time - os.clock()
        if message ~= nil then
            vlog("got update from ID", sender_id)
            g_current_stats_bucket[sender_id] = message
        end
    end
    g_current_stats_time = os.clock()
end

function backfillStatsForInactiveBots()
    if g_prev_stats_bucket == nil then
        return
    end
    for bot_id,prev_stats in pairs(g_prev_stats_bucket) do
        current_stats = g_current_stats_bucket[bot_id]
        if current_stats == nil then
            ilog("No new updates recieved for ID:", bot_id)
            g_current_stats_bucket[bot_id] = prev_stats
        end
    end
end

function aggregateBucketsAndPrintUpdate()
    if g_prev_stats_bucket == nil then
        total_count = 0
        for k,v in pairs(g_current_stats_bucket) do
            total_count = total_count + v.total_wool
        end
        ilog("Starting amount of wool", total_count)
        return
    end

    total_count = 0
    for bot_id,current_stats in pairs(g_current_stats_bucket) do
        prev_stats = g_prev_stats_bucket[bot_id]
        if prev_stats == nil then
            ilog("New bot came online!", bot_id, "with initial count",
                 current_stats.total_wool)
        else
            delta_wool = (current_stats.total_wool - prev_stats.total_wool)
            if delta_wool < 0 then
                ilog("Negative delta for ID", bot_id,
                     "it probably just reset its count")
                delta_wool = current_stats.total_wool
            end
            total_count = total_count + delta_wool
        end
    end

    if g_exponential_moving_average == nil then
        g_exponential_moving_average = total_count
    else
        prev_average = g_exponential_moving_average
        g_exponential_moving_average =
                g_exponential_moving_average_weight * total_count +
                (1 - g_exponential_moving_average_weight) * prev_average
    end

    ilog("collected", total_count, "wool",
         "(EMA=" .. g_exponential_moving_average .. ") in",
         g_current_stats_time - g_prev_stats_time, "seconds")
end

rednet.open("left")
while 1 do
    collectUpdates(60)
    backfillStatsForInactiveBots()
    aggregateBucketsAndPrintUpdate()

    g_prev_stats_bucket = g_current_stats_bucket
    g_prev_stats_time = g_current_stats_time

    g_current_stats_bucket = {}
end