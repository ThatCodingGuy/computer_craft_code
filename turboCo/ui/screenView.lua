local screenBuffer = require "turboCo.ui.screenBuffer"
local function create(args)
  local self = {
    screenBufferGroups = {}
  }

  local getScreenBuffersWithGroupName = function(groupName)
    for _,group in pairs(self.screenBufferGroups) do
      if group.name == groupName then
        return group
      end
    end
    local newGroup = {name = groupName, screenBuffers = {}}
    table.insert(self.screenBufferGroups, newGroup)
    return newGroup
  end

  local addScreenBuffer = function(args)
    local group = getScreenBuffersWithGroupName(args.groupName)
    table.insert(group.screenBuffers, args.screenBuffer)
  end

  return {
    addScreenBuffer=addScreenBuffer
  }

end

return {
  create=create
}