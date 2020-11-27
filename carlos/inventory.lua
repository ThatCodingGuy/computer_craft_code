-- Utilities to manage turtle's inventory.

local function selectItemWithName(name)
    for i=1,16 do
        local detail = turtle.getItemDetail(i)
        if detail and detail.name == name then
            turtle.select(i)
            return true
        end
    end
    return false
end
   
local function countItemWithName(name)
    local total_count = 0
    for i=1,16 do
        detail = turtle.getItemDetail(i)
        if detail and detail.name == name then
            total_count = total_count + detail.count
        end
    end
    return total_count
end