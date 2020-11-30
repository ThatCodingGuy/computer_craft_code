--A Page View is a list of screenBuffers where one is displayed at a time
-- All screen buffers should be of the same dimensions and 

local function create(eventHandler)
  local self = {
    pages = {},
    currPage = 0,
    eventHandler = eventHandler
  }

  local addPage = function(screenBuffer)
    table.insert(self.pages, screenBuffer)
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
    self.currPage = index
    local page = self.pages[self.currPage]
    page.renderScreen()
    return page
  end

  local switchToPreviousPage = function()
    if hasPreviousPage() then
      self.currPage = self.currPage - 1
    end
    local page = self.pages[self.currPage]
    page.renderScreen()
    return page
  end

  local switchToNextPage = function()
    if hasNextPage() then
      self.currPage = self.currPage + 1
    end
    switchToPage(self.currPage)
  end

  

  return {
    addPage=addPage,
    getPage=getPage,
    getPageIndex=getPageIndex,
    hasPreviousPage=hasPreviousPage,
    hasNextPage=hasNextPage,
    switchToPage=switchToPage,
    switchToPreviousPage=switchToPreviousPage,
    switchToNextPage=switchToNextPage
  }
end

return {
  create=create
}