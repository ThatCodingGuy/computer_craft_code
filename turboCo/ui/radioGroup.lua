--Creates a radio group from radio inputs

local function create(args)

  local self = {
    radioInputs = {},
    selectedRadioInput = nil
  }

  if args ~= nil and args.radioInputs ~= nil then
    self.radioInputs = args.radioInputs
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
    addRadioInput=addRadioInput,
    getSelected=getSelected
  }

end

return {
  create = create
}