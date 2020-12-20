local Logger = dofile("./gitlib/turboCo/logger.lua")

--- Gets the size of a file or directory and prints it in a human readable format.

local suffixes = {
    "B", "KB", "MB", "GB", "TB", "PB", "EB"
}

function traverse(file_path)
    if not fs.isDir(file_path) then
        return fs.getSize(file_path)
    end

    local sub_paths = fs.list(file_path)
    local total_size = 0
    for _, sub_path in ipairs(sub_paths) do
        total_size = total_size + traverse(file_path .. "/" .. sub_path)
    end
    return total_size
end

function human_readable_of(size)
    local current_size = size
    for i = 2, #suffixes do
        local new_size = current_size / 1024
        if new_size < 0 then
            return current_size .. suffixes[i - 1]
        end
        current_size = new_size
    end
    return "This is way too big."
end

Logger.log_level_filter = Logger.LoggingLevel.INFO
local logger = Logger.new()
local dir = arg[1]
if dir == nil or not fs.exists(dir) then
    logger.error("Expected a valid file path as argument")
end

local size = traverse(dir)
logger.info(human_readable_of(size))
