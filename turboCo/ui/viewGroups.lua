local function create()
  local self = {
    viewGroups = {}
  }

  local getViewsWithGroupName = function(groupName)
    for _,group in pairs(self.viewGroups) do
      if group.name == groupName then
        return group
      end
    end
    local newGroup = {name = groupName, views = {}}
    table.insert(self.viewGroups, newGroup)
    return newGroup
  end

  local addView = function(args)
    local group = getViewsWithGroupName(args.groupName)
    table.insert(group.views, args.view)
  end

  local makeGroupActive = function(group)
    for _,view in pairs(group.views) do
      view.makeActive()
    end
  end

  local makeGroupInactive = function(group)
    for _,view in pairs(group.views) do
      view.makeActive()
    end
  end

  local removeGroup = function(groupName)
    for index,group in pairs(self.viewGroups) do
      if group.name == groupName then
        groupIndex = index
      end
    end
    table.remove(self.viewGroups, groupIndex)
    if #self.viewGroups > 0 then
      makeGroupActive(self.viewGroups[1])
    end
  end

  local moveGroupToTop = function(groupName)
    local groupIndex = nil
    for index,group in pairs(self.viewGroups) do
      if group.name == groupName then
        groupIndex = index
      else
        makeGroupInactive(group)
      end
    end
    if groupIndex == nil then
      error(string.format('groupName: "%s" is not present in the screen group', groupName))
    end
    local group = table.remove(self.viewGroups, groupIndex)
    table.insert(self.viewGroups, 1, group)
    makeGroupActive(group)
  end

  return {
    addView=addView,
    removeGroup=removeGroup,
    moveGroupToTop=moveGroupToTop
  }

end

return {
  create=create
}