local function create(args)
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
    for _,view in group.views do
      view.makeActive()
    end
  end

  local makeGroupInactive = function(group)
    for _,view in group.views do
      view.makeActive()
    end
  end

  local moveGroupToTop = function(groupName)
    local groupIndex = nil
    for index,group in pairs(self.screenBufferGroups) do
      if group.name == groupName then
        groupIndex = index
      else
        makeGroupInactive(group)
      end
    end
    if groupIndex == nil then
      error(string.format('groupName: "%s" is not present in the screen group', groupName))
    end
    local group = table.remove(self.screenViewGroups, groupIndex)
    table.insert(self.screenViewGroups, group, 1)
    makeGroupActive(group)
  end

  

  return {
    addView=addView,
    moveGroupToTop=moveGroupToTop
  }

end

return {
  create=create
}