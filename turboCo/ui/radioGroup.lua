--Creates a radio group from radio inputs

local function create(args)

  local self = {
    radioInputs = {},
    selectedRadioInput = nil
  }

  if args ~= nil and args.radioInputs ~= nil then
    self.radioInputs = args.radioInputs
  end

  local clear = function()
    for _,radioInput in pairs(self.radioInputs) do
      radioInput.makeInactive()
    end
    self.radioInputs = {}
    self.selectedRadioInput = nil
  end

  local handleRadioInputClicked = function(clickedId)
    for _,radioInput in pairs(self.radioInputs) do
      local isSelected = clickedId == radioInput.getId()
      if isSelected then
        self.selectedRadioInput = radioInput
      end
      radioInput.setSelected(isSelected)
    end
  end

  local addRadioInput = function(radioInput)
    table.insert(self.radioInputs, radioInput)
    radioInput.addLeftClickCallback(handleRadioInputClicked)
  end

  local getSelected = function()
    return self.selectedRadioInput
  end

  for _,radioInput in pairs(self.radioInputs) do
    radioInput.addLeftClickCallback(handleRadioInputClicked)
  end

  return {
    clear=clear,
    addRadioInput=addRadioInput,
    getSelected=getSelected
  }

end

return {
  create = create
}