--[[
  request parameters:
    url: url of the request
    headers: table with the key-value pairs of the headers
    successCallback: what to run on success
    failureCallback = what to run on failure
    **note**: callback functions take the handle as well as optional extraArgs
    the handle is the response coming from the pullEvent data as specified in https://computercraft.info/wiki/Http_success_(event)
]]

local logger = dofile("./gitlib/turboCo/logger.lua").new()

local create = function(args)

  local self = {
    eventHandler=args.eventHandler,
    callbackData = {}
  }

  local handleHttpResponse = function(eventData, callbackField)
    local url, handle = eventData[2], eventData[3]
    local indexToRemove = nil
    for index,callbackObj in ipairs(self.callbackData) do
      if url == callbackObj.url then
        indexToRemove = index
        callbackObj[callbackField](handle, callbackObj.extraArgs)
      end
    end
    if indexToRemove then
      table.remove(self.callbackData, indexToRemove)
    end
  end

  local handleHttpSuccess = function(eventData)
    handleHttpResponse(eventData, 'successCallback')
  end

  local handleHttpFailure = function(eventData)
    handleHttpResponse(eventData, 'errorCallback')
  end

  local prepareRequest = function(args)
    if not args.successCallback then
      error('need to provide a "successCallback" arg. you dont care that your requests work?')
    end
    local errorCallback = args.errorCallback
    if not errorCallback then
      errorCallback = args.successCallback
    end
    table.insert(self.callbackData, {url=args.url, successCallback=args.successCallback, errorCallback=errorCallback, extraArgs=args.extraArgs})
  end

  local get = function(args)
    prepareRequest(args)
    http.request(args.url, nil, args.headers)
  end
  
  local post = function(args)
    prepareRequest(args)
    http.request(args.url, args.postData, args.headers)
  end

  self.eventHandler.addHandle("http_success", handleHttpSuccess)
  self.eventHandler.addHandle("http_failure", handleHttpFailure)

  return {
    get=get,
    post=post
  }
end

return {
  create=create
}