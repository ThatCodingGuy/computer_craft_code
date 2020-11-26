-- Controller which aggregates stats sent to the "shear_stats" protocol on rednet and displays in a per-minute basis.
--
-- The shear_stats protocol message should be a table with the keys:
-- 
--   total_wool: int  -- total amount of wool a bot currently has.

g_prev_stats_bucket = nil
g_prev_stats_time = nil

g_current_stats_bucket = {}
g_current_stats_time = nil

function collectUpdates(secs_to_wait)
    print("waiting for updates")
    end_time = os.time() + secs_to_wait
    secs_left = secs_to_wait
    while secs_left > 0 do
        sender_id, message = rednet.receive("shear_stats", secs_left)
        secs_left = end_time - os.time()
        if message ~= nil then
            print("Got update from ID", sender_id)
            g_current_stats_bucket[sender_id] = message
        end
    end
    g_current_stats_time = os.time()
end

function backfillStatsForInactiveBots()
    if g_prev_stats_bucket == nil then
        return
    end
    for bot_id,prev_stats in pairs(g_prev_stats_bucket) do
        current_stats = g_current_stats_bucket[bot_id]
        if current_stats == nil then
            print("No new updates recieved for ID:", bot_id)
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
        print("Starting amount of wool", total_count)
        return
    end

    total_count = 0
    for bot_id,current_stats in pairs(g_current_stats_bucket) do
        prev_stats = g_prev_stats_bucket[bot_id]
        if prev_stats == nil then
            print("New bot came online!", bot_id, "with initial count",
                  current_stats.total_wool)
        else
            delta_wool = (current_stats.total_wool - prev_stats.total_wool)
            if delta_wool < 0 then
                print("Negative delta for ID", bot_id,
                      "it probably just reset its count")
                delta_wool = current_stats.total_wool
            end
            total_count = total_count + delta_wool
        end
    end

    print("collected", total_count, "wool in",
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