local component = require("component")
local filesystem = require("Filesystem")
local paths = require("Paths")
local system = require("System")
local GUI = require("GUI")

local bar_height = 3
local color_val = 0x000000
local color_active = 0x009900
local color_passive = 0xF0F0F0

local stats = {}
stats["last_tick"] = 0
stats["max"] = 1
stats["stored"] = 0
stats["stored_max"] = 1
stats["rods"] = 0
stats["rod_max"] = 100
stats["rod_min"] = 0

------------------------------------------------------------------------------------------------------

if not component.isAvailable("br_reactor") then
    GUI.alert("This program needs a Big Reactor to work")
    return
end
local reactor = component.br_reactor

------------------------------------------------------------------------------------------------------

function getLastTickPrefix ()
    return "Power last tick: " .. stats["last_tick"] .. " RF/t ("
end
function getStoredPrefix ()
    return "Power stored: " .. stats["stored"] .. " RF ("
end
function getRodPrefix ()
    return "Rod insertion: "
end
function getSuffix ()
    return "%)"
end
function activate (active)
    reactor.setActive(active)
end

------------------------------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.titledWindow(1, 1, 88, 26, 'Extreme Reactors Controller', true));

local progressContainer = window:addChild(GUI.container(1, 2, math.floor(88 * 0.6), 26))
progressContainer.panel = progressContainer:addChild(GUI.panel(1, 1, progressContainer.width, progressContainer.height, 0xFFFFFF))
progressContainer.itemsContainer = progressContainer:addChild(GUI.container(1, 1, progressContainer.width, progressContainer.height))
progressContainer.panel.eventHandler = function()
    update()
end

progressPower = progressContainer.itemsContainer:addChild(GUI.progressBar(3, 2, 1, color_active, color_passive, color_val, 0, false, true, getLastTickPrefix(), getSuffix()))
progressStored = progressContainer.itemsContainer:addChild(GUI.progressBar(3, progressPower.y + bar_height + 1, 1, color_active, color_passive, color_val, 0, false, true, getStoredPrefix(), getSuffix()))
progressRod = progressContainer.itemsContainer:addChild(GUI.progressBar(3, progressStored.y + bar_height + 1, 1, color_active, color_passive, color_val, 0, false, true, getRodPrefix(), "%"))

local controlContainer = window:addChild(GUI.container(progressContainer.width + 1, 2, 1, 26))
controlContainer.panel = controlContainer:addChild(GUI.panel(1, 1, controlContainer.width + 1, controlContainer.height, 0xF0F0F0))
controlContainer.itemsContainer = controlContainer:addChild(GUI.container(1, 1, controlContainer.width + 1, controlContainer.height))

local b_on = controlContainer.itemsContainer:addChild(GUI.adaptiveRoundedButton(3, 2, 1, 0, 0xFFFFFF, 0x000000, 0x009900, 0xFFFFFF, "On"))
local b_off = controlContainer.itemsContainer:addChild(GUI.adaptiveRoundedButton(10, 2, 1, 0, 0xFFFFFF, 0x000000, 0xFF0000, 0xFFFFFF, "Off"))

local l_min = controlContainer.itemsContainer:addChild(GUI.label(4, 4, 10, 1, 0x000000, "Min: " .. stats["rod_min"] .. "%"))
local l_max = controlContainer.itemsContainer:addChild(GUI.label(15, 4, 10, 1, 0x000000, "Max: " .. stats["rod_max"] .. "%"))
local b_min_up = controlContainer.itemsContainer:addChild(GUI.framedButton(3, 5, 10, 3, 0x00ffff, 0x000000, 0x009900, 0x000000, "+10%"))
local b_min_down = controlContainer.itemsContainer:addChild(GUI.framedButton(3, 8, 10, 3, 0x00ffff, 0x000000, 0x009900, 0x000000, "-10%"))
local b_max_up = controlContainer.itemsContainer:addChild(GUI.framedButton(14, 5, 10, 3, 0xff00ff, 0x000000, 0x009900, 0x000000, "+10%"))
local b_max_down = controlContainer.itemsContainer:addChild(GUI.framedButton(14, 8, 10, 3, 0xff00ff, 0x000000, 0x009900, 0x000000, "-10%"))

------------------------------------------------------------------------------------------------------

local function adjustRods ()

    rfTotalMax = 10000000
    currentRf = stats["stored"]

    differenceMinMax = stats["rod_max"] - stats["rod_min"]

    local maxPower = (rfTotalMax / 100) * stats["rod_max"]
    local minPower = (rfTotalMax / 100) * stats["rod_min"]

    if currentRf >= maxPower then
        currentRf = maxPower
    end
    if currentRf <= minPower then
        currentRf = minPower
    end

    currentRf = currentRf - (rfTotalMax / 100) * stats["rod_min"]
    local rfInBetween = (rfTotalMax / 100) * differenceMinMax
    local rodLevel = math.ceil((currentRf / rfInBetween) * 100)

    reactor.setAllControlRodLevels(rodLevel)
end

local function modifyRods (limit, amount)

    local temp = 0

    if limit == "min" then
        temp = stats["rod_min"] + amount

        if temp <= 0 then
            temp = 0
        end
        if temp >= stats["rod_max"] then
            stats["rod_min"] = stats["rod_max"] - 10
        end

        if temp < stats["rod_max"] and temp > 0 then
            stats["rod_min"] = temp
        end
    else
        temp = stats["rod_max"] + amount

        if temp <= stats["rod_min"] then
            stats["rod_max"] = stats["rod_min"] + 10
        end
        if temp >= 100 then
            stats["rod_max"] = 100
        end

        if temp > stats["rod_min"] and temp < 100 then
            stats["rod_max"] = temp
        end
    end

    adjustRods()
end

local function calculateSizes (width, height)

    window.titleLabel.width = width
    window.titlePanel.width = width
    window.backgroundPanel.width = width
    window.backgroundPanel.height = height
    window.backgroundPanel.localX = 1
    window.backgroundPanel.localY = 4

    progressContainer.height = height
    progressContainer.width = math.floor(width * 0.6)
    progressContainer.panel.height = progressContainer.height
    progressContainer.panel.width = progressContainer.width
    progressContainer.itemsContainer.height = progressContainer.height
    progressContainer.itemsContainer.width = progressContainer.width

    progressPower.height = bar_height
    progressStored.height = bar_height
    progressRod.height = bar_height
    progressPower.width = progressContainer.width - 4
    progressStored.width = progressContainer.width - 4
    progressRod.width = progressContainer.width - 4

    controlContainer.height = height
    controlContainer.width = width - progressContainer.width
    controlContainer.localX = progressContainer.width + 1
    controlContainer.panel.height = controlContainer.height
    controlContainer.panel.width = controlContainer.width
    controlContainer.itemsContainer.height = controlContainer.height
    controlContainer.itemsContainer.width = controlContainer.width

    controlContainer:moveToFront()
    window.actionButtons:moveToFront()
end

function update ()

    stats["last_tick"] = math.ceil(reactor.getEnergyProducedLastTick())
    stats["stored"] = math.ceil(reactor.getEnergyStored())
    stats["rods"] = math.ceil(reactor.getControlRodLevel(0))

    if stats["max"] < stats["last_tick"] then
        stats["max"] = stats["last_tick"]
    end
    if stats["stored_max"] < stats["stored"] then
        stats["stored_max"] = stats["stored"]
    end

    progressPower.value = math.ceil(stats["last_tick"] / stats["max"] * 100)
    progressStored.value = math.ceil(stats["stored"] / stats["stored_max"] * 100)
    progressRod.value = stats["rods"]
    progressPower.valuePrefix = getLastTickPrefix()
    progressStored.valuePrefix = getStoredPrefix()

    b_on.disabled = reactor.getActive()
    b_off.disabled = not reactor.getActive()

    l_min.text = "Min: " .. stats["rod_min"] .. "%"
    l_max.text = "Max: " .. stats["rod_max"] .. "%"

    adjustRods()
    workspace:draw()
end

------------------------------------------------------------------------------------------------------

b_on.onTouch = function()
    activate(true)
end
b_off.onTouch = function()
    activate(false)
end

b_min_up.onTouch = function()
    modifyRods("min", 10)
end
b_min_down.onTouch = function()
    modifyRods("min", -10)
end
b_max_up.onTouch = function()
    modifyRods("max", 10)
end
b_max_down.onTouch = function()
    modifyRods("max", -10)
end

local reactor_path = paths.user.applicationData .. "Reactors/Cache.cfg"
if filesystem.exists(reactor_path) then
    stats = filesystem.readTable(reactor_path)
    update()
end

local close = window.actionButtons.close.onTouch
window.actionButtons.close.onTouch = function()
    filesystem.writeTable(reactor_path, stats)
    close()
end

window.onResize = function(width, height)
    calculateSizes(width, height)
    workspace:draw()
end
window:resize(window.width, window.height)
