--Creates a button on your screenBuffer
--Has mouse hover, mouse click, and mouse

local function create(text, primaryColor, secondaryColor, clickCallback)
  local self = {
    text=text,
    primaryColor=primaryColor,
    secondaryColor=secondaryColor,
    clickCallback=clickCallback
  }

  return {

  }
end

return {
  create = create
}