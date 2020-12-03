--A Page View is a list of pages where one is displayed at a time
-- All screen buffers should be of the same dimensions and positions

local function create(eventHandler)
  local self = {
    pages = {},
    currPage = 0,
    eventHandler = eventHandler,
    scrollHandler = nil
  }

  local setScrollHandler = function(scrollHandler)
    self.scrollHandler = scrollHandler
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
    if self.scrollHandler ~= nil then
      self.scrollHandler.changeScreenBuffer(page.getScreenBuffer())
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

  return {
    setScrollHandler=setScrollHandler,
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