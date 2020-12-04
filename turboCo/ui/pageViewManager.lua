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
    postPageChangeCallback = args.postPageChangeCallback
    scrollHandler = args.scrollHandler
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

  local leftButtonClickCallback = function()
    if self.leftButtonOrigCallback ~= nil then
      self.leftButtonOrigCallback()
    end
    switchToPreviousPage()
  end

  local rightButtonClickCallback = function()
    if self.rightButtonOrigCallback ~= nil then
      self.rightButtonOrigCallback()
    end
    switchToNextPage()
  end

  if self.leftButton ~= nil then
    self.leftButtonOrigCallback = self.leftButton.getLeftClickCallback()
    self.leftButton.setLeftClickCallback(leftButtonClickCallback)
  end

  if self.rightButton ~= nil then
    self.rightButtonOrigCallback = self.rightButton.getLeftClickCallback()
    self.rightButton.setLeftClickCallback(rightButtonClickCallback)
  end

  return {
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