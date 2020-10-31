local component = require("Component")
local fs = require("Filesystem")
local internet = require("Internet")
local system = require("System")
local GUI = require("GUI")
local event = require("Event")
 
local currentScriptDirectory = fs.path(system.getCurrentScript())
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/")
 
local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 85, 18, 0x0)) --  окно 0xF0F0F0
 window.backgroundPanel.colors.transparency = 0.4

if not component.isAvailable("tape_drive") then
  GUI.alert(localization.noConnectionBlock)
  window:remove()
end
 
local function addButton(x, y, text)
  return window:addChild(GUI.roundedButton(x, y, 25, 1, 0x3C3C3C, 0xE1E1E1, 0xFFFFFF, 0x2D2D2D, text))
end
 
tape = component.get("tape_drive")
 
local function checkKasset()
if not tape.isReady() then
  GUI.alert(localization.noTape)
end
end
 
addButton(30, 11, localization.playTape).onTouch = function()
checkKasset()
 if tape.getState() == "PLAYING" then
    GUI.alert(localization.playingTape)
  else
    tape.play()
    GUI.alert(localization.startPlayTape)
  end
end
 
addButton(58, 11, localization.stopTape).onTouch = function()
checkKasset()
if tape.getState() == "STOPPED" then
    GUI.alert(localization.stoppedTape)
  else
    tape.stop()
    tape.seek(-tape.getSize())
    GUI.alert(localization.stopTape1)
  end
end
 
addButton(30, 13, localization.replay).onTouch = function()
checkKasset()
tape.seek(-tape.getSize())
tape.play()
end
 
addButton(3, 11, localization.pauseTape).onTouch = function()
checkKasset()
  if tape.getState() == "STOPPED" then
    GUI.alert(localization.tapePaused)
  else
    tape.stop()
    GUI.alert(localization.tapeSetPause)
  end
end
 
  local sliderSpeed = window:addChild(GUI.slider(35, 15, 15, 0x66DB80, 0x878787, 0xFFFFFF, 0xAAAAAA, 0.25, 2, 1, true, localization.speedSlider, "x"))
   sliderSpeed.onValueChanged = function()
   tape.setSpeed(sliderSpeed.value)
  end

  addButton(3, 17, localization.defaultSpeed).onTouch = function()
  checkKasset()
  tape.setSpeed(1.0)
  end
   
   local sliderVolume = window:addChild(GUI.slider(63, 15, 15, 0x66DB80, 0x878787, 0xFFFFFF, 0xAAAAAA, 0.0, 1, 1, true, localization.volumeSlider, "%"))
   sliderVolume.onValueChanged = function()
   tape.setVolume(sliderVolume.value)
   end
   
   addButton(3, 13, localization.renameTape).onTouch = function()
   checkKasset()
   local nameContainer = GUI.addBackgroundContainer(window, true, true, localization.nameTape)
   local nameInput = nameContainer.layout:addChild(GUI.input(1, 1, 30, 3, 0xC3C3C3, 0x787878, 0x0092FF, 0xFFFFFF, 0x000000, ""))
   nameContainer.layout:addChild(GUI.roundedButton(1, 1, 24, 1, 0xE1E1E1, 0x3C3C3C, 0xFFFFFF, 0x2D2D2D, "OK")).onTouch = function()
    tape.setLabel(nameInput.text)
   end
   end
   
   addButton(58, 13, localization.writeTape).onTouch = function()
   local file
   tape.stop()
   tape.seek(-tape.getSize())
   tape.stop()
   
   local writeContainer = GUI.addBackgroundContainer(workspace, true, true, localization.containerWriteTape)
 
  local filesystemChooser = writeContainer.layout:addChild(GUI.filesystemChooser(2, 2, 30, 3, 0xE1E1E1, 0x888888, 0x3C3C3C, 0x888888, nil, "Open", "Cancel", "Write", "/"))
    filesystemChooser:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
    filesystemChooser.onSubmit = function(path)
      file = fs.read(path)
      local filesize = fs.size(path)
 
     if filesize > tape.getSize() then
        error(localization.sizelong)
        filesize = tape.getSize()
     end
 
    tape.stop()
    tape.seek(-tape.getSize())
    tape.stop() --Just making sure
   local k = tape.getSize()
   tape.seek(-90000)
  local s = string.rep("\xAA", 8192)
  for i = 1, k + 8191, 8192 do
    tape.write(s)
  end
  tape.seek(-k)
  tape.seek(-90000)
 
    tape.write(file)
    GUI.alert(localization.writedTape)
    end
    end
   
  addButton(3, 15, localization.wipeTape).onTouch = function()
    local k = tape.getSize()
  tape.stop()
  tape.seek(-k)
  tape.stop() --Just making sure
  tape.seek(-90000)
  local s = string.rep("\xAA", 8192)
  for i = 1, k + 8191, 8192 do
    tape.write(s)
  end
  tape.seek(-k)
  tape.seek(-90000)
  GUI.alert(localization.wipedTape)
  end
