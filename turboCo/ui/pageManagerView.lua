--A Page View is a list of pages where one is displayed at a time
-- All screen buffers should be of the same dimensions and positions

local function create(args)
  local self = {
    pages = {},
    currPage = 0,
    eventHandler = args.eventHandler,
    leftButton = args.leftButton,
    leftButtonOrigCallback = nil,
    rightButton = args.rightButton,
    rightButtonOrigCallback = nil,
    postPageChangeCallback = args.postPageChangeCallback,
  }

  local getPage = function()
    return self.pages[self.currPage]
  end

  local getPageIndex = function()
    return self.currPage
  end

  local hasPreviousPage = function()
    return self.currPage > 1
  end

  local hasNextPage = function()
    return self.currPage < #self.pages
  end

  local render = function()
    local page = getPage()
    if page then
      page.render()
    end
  end

  local addClickable = function(clickable)
    local page = getPage()
    if page then
      page.addClickable(clickable)
    end
  end

  local makeActive = function()
    local page = getPage()
    if page then
      page.makeActive()
    end
  end

  local makeInactive = function()
    local page = getPage()
    if page then
      page.makeInactive()
    end
  end

  local switchToPage = function(index)
    if self.currPage > 0 then
      makeInactive()
    end
    self.currPage = index
    makeActive()

    if self.postPageChangeCallback ~= nil then
      self.postPageChangeCallback()
    end
    return getPage()
  end

  local switchToPreviousPage = function()
    if hasPreviousPage() then
      return switchToPage(self.currPage - 1)
    end
  end

  local switchToNextPage = function()
    if hasNextPage() then
      return switchToPage(self.currPage + 1)
    end
  end

  local addPage = function(page)
    table.insert(self.pages, page)
  end

  local addAndSwitchToPage = function(page)
    addPage(page)
    switchToPage(#self.pages)
  end

  if self.leftButton ~= nil then
    self.leftButton.addLeftClickCallback(switchToPreviousPage)
  end

  if self.rightButton ~= nil then
    self.rightButton.addLeftClickCallback(switchToNextPage)
  end

  return {
    getPage=getPage,
    getPageIndex=getPageIndex,
    hasPreviousPage=hasPreviousPage,
    hasNextPage=hasNextPage,
    render=render,
    addClickable=addClickable,
    makeActive=makeActive,
    makeInactive=makeInactive,
    switchToPage=switchToPage,
    switchToPreviousPage=switchToPreviousPage,
    switchToNextPage=switchToNextPage,
    addPage=addPage,
    addAndSwitchToPage=addAndSwitchToPage
  }
end

return {
  create=create
}