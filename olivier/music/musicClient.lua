local json = dofile("./gitlib/turboCo/json.lua")
local EventHandler = dofile("./gitlib/turboCo/event/eventHandler.lua")
local ScreenBuffer = dofile("./gitlib/turboCo/ui/screenBuffer.lua")
local RadioGroup = dofile("./gitlib/turboCo/ui/radioGroup.lua")
local RadioInput = dofile("./gitlib/turboCo/ui/radioInput.lua")
local Button = dofile("./gitlib/turboCo/ui/button.lua")
local ExitHandler = dofile("./gitlib/turboCo/ui/exitHandler.lua")
local ScreenContent = dofile("./gitlib/turboCo/ui/screenContent.lua")
local ScrollView = dofile("./gitlib/turboCo/ui/scrollView.lua")
local Util = dofile("./gitlib/turboCo/util.lua")
local MusicConstants = dofile("./gitlib/olivier/music/musicConstants.lua")
local Logger = dofile("./gitlib/turboCo/logger.lua")
local logger = Logger.new()
local loggingLevel = "ERROR"
if LOGGING_LEVEL then
  loggingLevel = LOGGING_LEVEL
end
Logger.log_level_filter = Logger.LoggingLevel[loggingLevel]

os.loadAPI('./gitlib/turboCo/modem.lua')
modem.openModems()

local screenSide = SCREEN_SIDE
local screen = nil
if screenSide == nil then
  screen, screenSide = Util.findPeripheral("monitor")
  if screen == nil then
    screen = term.current()
    screenSide = "term"
  end
elseif screenSide == "term" then
  screen = term.current()
else
  screen = peripheral.wrap(screenSide)
  if screen == nil then
    error(string.format('screen of side: "%s" is not found. change the config.', screenSide))
  end
end
screen.clear()
local width,height = screen.getSize()

--UI Components
local screenTitleBuffer = nil
local progressScreenContent = nil
local speedScreenContent = nil
local volumeScreenContent = nil
local controlScreenBuffer = nil
local musicView = nil
local musicViewScreenBuffer = nil
local musicControlsBuffer = nil
local nowPlayingBuffer = nil
local nowPlayingScreenContent = nil

--Client State
local serverId = nil

local radioGroup = RadioGroup.create()
local eventHandler = EventHandler.create()
local exitHandler = ExitHandler.createFromScreen(screen, eventHandler)

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

local function validateNotNil(messageObj, objPath)
  if not messageObj and messageObj[objPath] then
    error(string.format('message is missing parameter: \"%s\"', objPath))
    return false
  end
  return true
end

local function sendMessageToServer(messageObj)
  if serverId == nil then
    serverId = rednet.lookup(MusicConstants.MUSIC_SERVER_PROTOCOL)
    if serverId == nil then
      error('no music server registered for hostname lookup')
    end
  end
  local message = json.encode(messageObj)
  rednet.send(serverId, message, MusicConstants.MUSIC_SERVER_PROTOCOL)
end

function speedIncreased(messageObj)
  if not validateNotNil(messageObj, 'tapeSpeed') then
    error('no tapeSpeed given from response')
  end
  speedScreenContent.updateText{text=messageObj.tapeSpeed, render=true}
  logger.debug("increasing speed to: ", messageObj.tapeSpeed)
end

function speedDecreased(messageObj)
  if not validateNotNil(messageObj, 'tapeSpeed') then
    error('no tapeSpeed given from response')
  end
  speedScreenContent.updateText{text=messageObj.tapeSpeed, render=true}
  logger.debug("decreasing speed to: ", messageObj.tapeSpeed)
end

function volumeIncreased(messageObj)
  if not validateNotNil(messageObj, 'tapeVolume') then
    error('no tapeVolume given from response')
  end
  volumeScreenContent.updateText{text=messageObj.tapeVolume, render=true}
  logger.debug("decreasing volume to: ", messageObj.tapeVolume)
end

function volumeDecreased(messageObj)
  if not validateNotNil(messageObj, 'tapeVolume') then
    error('no tapeVolume given from response')
  end
  volumeScreenContent.updateText{text=messageObj.tapeVolume, render=true}
  logger.debug("decreasing volume to: ", messageObj.tapeVolume)
end

function writeMusicProgress(messageObj)
  if not validateNotNil(messageObj, 'percentage') then
    error('no percentage given from response')
  end
  if not validateNotNil(messageObj, 'fileName') then
    error('no fileName given from response')
  end
  progressScreenContent.updateText{text = string.format("%s%%", messageObj.percentage), render=true}
  nowPlayingScreenContent.updateText{text=string.format("%s", messageObj.fileName), render=true}
end

function writeTapeProgress(messageObj)
  if not validateNotNil(messageObj, 'percentage') then
    error('no percentage given from response')
  end
  local progressText = string.format("%s%%", messageObj.percentage)
  progressScreenContent.updateText{text=progressText, render=true}
  nowPlayingScreenContent.updateText{text="Writing...", render=true}
end

function musicPlayed(messageObj)
  if not validateNotNil(messageObj, 'fileName') then
    error('no fileName given from response')
  end
  local nowPlayingText = string.format("%s", messageObj.fileName)
  nowPlayingScreenContent.updateText{text=nowPlayingText, render=true}
end

function musicStopped(messageObj)
  local nowPlayingText = "Stopped"
  nowPlayingScreenContent.updateText{text=nowPlayingText, render=true}
end

function musicStateReceived(messageObj)
  if not validateNotNil(messageObj, 'musicList') then
    error('no musicList given from response')
  end
  if not validateNotNil(messageObj, 'tapeSpeed') then
    error('no tapeSpeed given from response')
  end
  if not validateNotNil(messageObj, 'tapeVolume') then
    error('no tapeVolume given from response')
  end
  musicViewScreenBuffer.clear()
  musicViewScreenBuffer.ln()
  radioGroup.clear()
  for _,music in pairs(messageObj.musicList) do
    radioGroup.addRadioInput(RadioInput.create{
      id=music.filePath,
      title=music.fileName,
      screenBuffer=musicViewScreenBuffer,
      screenBufferWriteFunc=musicViewScreenBuffer.writeLn,
      eventHandler=eventHandler
    })
  end
  musicViewScreenBuffer.render()
  speedScreenContent.updateText({text=messageObj.tapeSpeed, render=true})
  volumeScreenContent.updateText({text=messageObj.tapeVolume, render=true})
end

function getMusicState()
  sendMessageToServer({command=MusicConstants.GET_MUSIC_STATE_COMMAND})
end

function play()
  local selectedRadioInput = radioGroup.getSelected()
  if selectedRadioInput ~= nil then
    sendMessageToServer({command=MusicConstants.PLAY_COMMAND, filePath=selectedRadioInput.getId()})
  end
end

function stop()
  sendMessageToServer({command=MusicConstants.STOP_COMMAND})
end

function increaseSpeed()
  sendMessageToServer({command=MusicConstants.INCREASE_SPEED_COMMAND})
end

function decreaseSpeed()
  sendMessageToServer({command=MusicConstants.DECREASE_SPEED_COMMAND})
end

function increaseVolume()
  sendMessageToServer({command=MusicConstants.INCREASE_VOLUME_COMMAND})
end

function decreaseVolume()
  sendMessageToServer({command=MusicConstants.DECREASE_VOLUME_COMMAND})
end

local responseToFunc = {
  [MusicConstants.GET_MUSIC_STATE_COMMAND]=musicStateReceived,
  [MusicConstants.STOP_COMMAND]=musicStopped,
  [MusicConstants.PLAY_COMMAND]=musicPlayed,
  [MusicConstants.TAPE_WRITE_PROGRESS_RESPONSE_TYPE]=writeTapeProgress,
  [MusicConstants.PLAYING_PROGRESS_RESPONSE_TYPE]=writeMusicProgress,
  [MusicConstants.INCREASE_SPEED_COMMAND]=speedIncreased,
  [MusicConstants.DECREASE_SPEED_COMMAND]=decreaseSpeed,
  [MusicConstants.INCREASE_VOLUME_COMMAND]=increaseVolume,
  [MusicConstants.DECREASE_VOLUME_COMMAND]=decreaseVolume
}

function rednetMessageReceived(eventData)
  local senderId, message, protocol = eventData[2], eventData[3], eventData[4]
  if protocol ~= MusicConstants.MUSIC_CLIENT_PROTOCOL then
    return
  end
  local messageObj = json.decode(message)
  if messageObj ~= nil  and messageObj.error then
    error(messageObj.error)
  elseif not validateNotNil(messageObj, 'command') then
    return
  end
  local responseFunc = responseToFunc[messageObj.command]
  if not responseFunc then
    error(string.format('Unrecognized command "%s" sent.', messageObj.command))
    return
  end
  responseFunc(messageObj)
end

screenTitleBuffer = ScreenBuffer.createFromOverrides{screen=screen, bottomOffset=height-1, bgColor=colors.yellow, textColor=colors.gray}
screenTitleBuffer.writeCenter{text="-- Music Player --"}
Button.create{
  screenBuffer=screenTitleBuffer,
  screenBufferWriteFunc=screenTitleBuffer.writeRight,
  eventHandler=eventHandler,
  text=" x",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=exitHandler.exit
}
screenTitleBuffer.render()

controlScreenBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=1, bottomOffset=height-2, bgColor=colors.blue, textColor=colors.white}
controlScreenBuffer.write{text="  "}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="+",
  textColor=colors.white,
  bgColor=colors.green,
  leftClickCallback=increaseSpeed
}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="-",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=decreaseSpeed
}
controlScreenBuffer.write{text=" Speed: "}

speedScreenContent = ScreenContent.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="1x"
}

--Adds padding
--controlScreenBuffer.write{text="        "}
controlScreenBuffer.write{text=" "}

Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="+",
  textColor=colors.white,
  bgColor=colors.green,
  leftClickCallback=increaseVolume
}
Button.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="-",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=decreaseVolume
}

controlScreenBuffer.write{text=" Volume: "}
volumeScreenContent = ScreenContent.create{
  screenBuffer=controlScreenBuffer,
  eventHandler=eventHandler,
  text="50%"
}
controlScreenBuffer.render()

musicView = ScrollView.createFromOverrides{screen=screen, eventHandler=eventHandler, topOffset=2, bottomOffset=2, bgColor=colors.purple, color=colors.white}
musicViewScreenBuffer = musicView.getScreenBuffer()
musicViewScreenBuffer.render()

musicControlsBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=height-2, bottomOffset=1, bgColor=colors.blue, textColor=colors.white}
Button.create{
  screenBuffer=musicControlsBuffer,
  screenBufferWriteFunc=musicControlsBuffer.writeLeft,
  eventHandler=eventHandler, 
  text=" Play ", 
  textColor=colors.white, 
  bgColor=colors.green,
  leftClickCallback=play
}

Button.create{
  screenBuffer=musicControlsBuffer,
  screenBufferWriteFunc=musicControlsBuffer.writeRight,
  eventHandler=eventHandler, 
  text=" Stop ",
  textColor=colors.white,
  bgColor=colors.red,
  leftClickCallback=stop
}

progressScreenContent = ScreenContent.create{
  screenBuffer=musicControlsBuffer,
  screenBufferWriteFunc=musicControlsBuffer.writeCenter,
  text="",
}
musicControlsBuffer.render()

nowPlayingBuffer = ScreenBuffer.createFromOverrides{screen=screen, topOffset=height-1, bgColor=colors.yellow, textColor=colors.gray}
nowPlayingScreenContent = ScreenContent.create{
  screenBuffer=nowPlayingBuffer,
  screenBufferWriteFunc=nowPlayingBuffer.writeCenter,
  text="",
}
nowPlayingBuffer.render()

eventHandler.addHandle("rednet_message", rednetMessageReceived)
getMusicList()

--Loops until exit handle quits it
eventHandler.pullEvents()