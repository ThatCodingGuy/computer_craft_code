--- Utilities to manage turtle's inventory.

--- Selects the slot of the first item for which `matcher` returns true.
-- Matcher must be a function accepting a single parameter that contains details of an item,
-- as obtained from a call to `turtle.getItemDetail`, and must return true if the item is a match,
-- and false otherwise.
-- @return True if an item slot was successfully selected, false otherwise.
local function selectItemMatching(matches)
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail and matches(detail) then
            turtle.select(i)
            return true
        end
    end
    return false
end

--- Selects the first item slot where the item name is equal to `name`.
-- @return True if an item slot was successfully selected, false otherwise.
local function selectItemWithName(name)
    return selectItemMatching(function(itemDetails)
        return itemDetails.name == name
    end)
end

--- Returns the count of the number of items, in all slots, where `matcher` returns true.
-- Matcher must be a function accepting a single parameter that contains details of an item,
-- as obtained from a call to `turtle.getItemDetail`, and must return true if the item is a match,
-- and false otherwise.
local function countItemMatching(matches)
    local total_count = 0
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail and matches(detail) then
            total_count = total_count + detail.count
        end
    end
    return total_count
end

--- Returns the count of the number of items, in all slots, having the name `name`.
local function countItemWithName(name)
    return countItemMatching(function(itemDetails)
        return itemDetails.name == name
    end)
end

return {
    selectItemWithNameMatching = selectItemMatching,
    selectItemWithName = selectItemWithName,
    countItemMatching = countItemMatching,
    countItemWithName = countItemWithName,
}