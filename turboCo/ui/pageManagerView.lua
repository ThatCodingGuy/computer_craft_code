--A Page View is a list of pages where one is displayed at a time
-- All screen buffers should be of the same dimensions and positions

local function create(args)
  local self = {
    view = {},
    currPage = 0,
    eventHandler = args.eventHandler,
    leftButton = args.leftButton,
    leftButtonOrigCallback = nil,
    rightButton = args.rightButton,
    rightButtonOrigCallback = nil,
    postPageChangeCallback = args.postPageChangeCallback,
  }

  local render = function()

  end

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

  local switchToPage = function(index)
    if self.currPage > 0 then
      local page = self.pages[self.currPage]
      page.makeInactive()
    end
    self.currPage = index
    local page = self.pages[self.currPage]
    page.makeActive()

    if self.postPageChangeCallback ~= nil then
      self.postPageChangeCallback()
    end
    return page
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
    render=render,
    getPage=getPage,
    getPageIndex=getPageIndex,
    hasPreviousPage=hasPreviousPage,
    hasNextPage=hasNextPage,
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