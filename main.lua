-- Prepare variables
local sUtils = require("sUtils")
local button = require("button")
local pg = require("progressBar")
local monSkimg = sUtils.asset.load("assets/monitor.skimg")
local termSkimg = sUtils.asset.load("assets/terminal.skimg")
local config = sUtils.encfread(".reactor.conf")
local mon = peripheral.wrap(config.monitor)
mon.setTextScale(0.5)
local reactor = peripheral.wrap(config.reactor)
reactor.setAllControlRodLevels(0)

local function difference(a,b)
  local c = b - a
  return math.floor((c / a) * 100)
end

local function gatherData()
  while true do
    local rfMax = reactor.getMaxEnergyStored()
    local rf = reactor.getEnergyStoredUnscaled()
    local rfLastTick = reactor.getEnergyProducedLastTick()
    local rfDifference = difference(rfLastTick,rf)
    local bufferPercentage = math.floor((rf / rfMax) * 100)
    local fuelTemp = reactor.getFuelTemperature()
    local caseTemp = reactor.getCaseTemperature()
    local fuelTempPercent = math.floor((fuelTemp / 2000) * 100)
    local caseTempPercent = math.floor((caseTemp / 2000) * 100)
    local active = reactor.getActive()
    local fuel = reactor.getFuelAmount()
    local fuelMax = reactor.getFuelAmountMax()
    local fuelPercent = math.floor((fuel / fuelMax) * 100)
    local waste = reactor.getWasteAmount()
    local wastePercent = math.floor((waste / fuelMax) * 100)
    local activelyCooled = reactor.isActivelyCooled()
    local controlRodDepth = reactor.getControlRodLevel(0)
    local water,waterMax,waterPercent,steam,steamMax,steamPercent,steamLastTick,steamMaxLastTick,steamDifference
    if activelyCooled then
      water = reactor.getCoolantAmount()
      waterMax = reactor.getCoolantAmountMax()
      waterPercent = math.floor((water / waterMax) * 100)
      steam = reactor.getHotFluidAmount()
      steamMax = reactor.getHotFluidMax()
      steamPercent = math.floor((steam / steamMax) * 100)
      steamDifference = difference(steamLastTick,steam)
      steamLastTick = reactor.getHotFluidProducedLastTick()
      steamMaxLastTick = reactor.getMaxHotFluidProducedLastTick()
    end
    local data = {
      rfMax = rfMax, rf = rf, rfLastTick = rfLastTick, rfDifference = rfDifference, bufferPercentage = bufferPercentage, controlRodDepth = controlRodDepth,
      fuelTemp = fuelTemp, caseTemp = caseTemp, fuelTempPercent = fuelTempPercent, caseTempPercent = caseTempPercent,
      active = active, fuel = fuel, fuelMax = fuelMax, fuelPercent = fuelPercent, waste = waste, wastePercent = wastePercent,
      activelyCooled = activelyCooled, water = water, waterMax = waterMax, waterPercent = waterPercent, steam = steam, steamMax = steamMax, steamPercent = steamPercent, steamLastTick = steamLastTick, steamMaxLastTick = steamMaxLastTick, steamDifference = steamDifference,
    }
    os.queueEvent("reactorData",data) 
    sleep(0.05)
  end
end

-- Setup progress bars
-- Colour lookup:
-- colours.orange: control rod bar 
-- colour.magenta: fuel bar
-- colours.lightBlue: waste bar 
-- colours.yellow: case heat bar 
-- colours.lime: fuel heat bar 
-- colours.pink: energy/cold coolant bar 
-- colours.cyan: hot coolant bar 

local function convertColour(col,barPercentage)
  local p = barPercentage/100
  mon.setPaletteColour(col, 1-p,p,0)
end

local function toSI(x) 
  local sizes = {"","Ki","Mi","Gi","Ti"}
  local i = math.floor(math.log(x) / math.log(1024))
  return tostring(string.format("%0.2f", (x / 1024 ^ i))) .. sizes[i]
end

local controlBar = pg.create(2,9,37,1,colours.orange,colours.grey,nil,mon)
local fuelBar = pg.create(2,27,23,1,colours.magenta,colours.grey,nil,mon)
local wasteBar = pg.create(2,29,23,1,colours.lightBlue,colours.grey,nil,mon)
local caseHeatBar = pg.create(2,31,23,1,colours.yellow,colours.grey,nil,mon) 
local fuelHeatBar = pg.create(2,33,23,1,colours.lime,colours.grey,nil,mon) 
local energyBar = pg.create(2,35,23,1,colours.pink,colours.grey,nil,mon)
local hotCoolantBar
if reactor.isActivelyCooled() then
  hotCoolantBar = pg.create(2,37,23,1,colours.cyan,nil,mon)
end

local bReactOn = button.newButton(53,34,3,3,function() reactor.setActive(true) end)
local bReactOff = button.newButton(48,34,3,3,function() reactor.setActive(false) end)
local bRodIncrease = button.newButton(37,11,3,3,function()
  local controlRodDepth = reactor.getControlRodLevel(0)
  if controlRodDepth < 100 then
    controlRodDepth = controlRodDepth + 1
    reactor.setAllControlRodLevels(controlRodDepth)
  end
end)
local bRodDecrease = button.newButton(2,11,3,3,function()
  local controlRodDepth = reactor.getControlRodLevel(0)
  if controlRodDepth > 0 then
    controlRodDepth = controlRodDepth - 1
    reactor.setAllControlRodLevels(controlRodDepth)
  end
end)

local function drawData()
  while true do
    local _,data = os.pullEvent("reactorData")
    -- Draw the terminal stuffs first, because this is easy.
    term.setCursorPos(5,4)
    term.setBackgroundColour(colours.lightGrey)
    if data.active then
      term.setTextColour(colours.lime)
      term.write("Running")
    else
      term.setTextColour(colours.red)
      term.write("Stopped")
    end
    -- Now draw all the other stuffs!
    -- Reactor toggle button
    if data.active then
      for x=30,3 do
        mon.setCursorPos(52,x) 
        mon.blit("   ","fff","ddd")
      end
    else
      for x=30,3 do
        mon.setCursorPos(52,x)
        mon.blit("   ","fff","eee")
      end
    end
    -- Draw energy outputs, with data
    if data.activelyCooled then
      mon.setCursorPos(2,14)
      mon.blit(" Fluid","000000","bbbbbb")
      mon.setCursorPos(20,15)
      mon.blit("B/t   ","000000","bbbbbb")
      mon.setCursorPos(20,16)
      mon.blit("B/t   ","000000","bbbbbb")
      -- Draw the actual data
      mon.setCursorPos(14,15)
      mon.setTextColour(colours.white)
      mon.setBackgroundColour(colours.blue)
      mon.write(sUtils.cut(tostring(data.steam),5))
      mon.setCursorPos(14,16)
      mon.write(sUtils.cut(tostring(data.steamLastTick),5))
      -- Draw the difference
      local difString = "-" .. sUtils.cut(tostring(data.steamDifferenceDifference),3) .. "+"
      mon.setCursorPos(14,17)
      if data.steamDifferenceDifference < 0 then
        mon.blit(difString,"e0008","bbbbb")
      elseif data.steamDifferenceDifference > 0 then
        mon.blit(difString,"8000d","bbbbb")
      else
        mon.blit(difString,"80008","bbbbb")
      end
      -- Draw the progress bars
      mon.setCursorPos(2,34)
      mon.write("Cold")
      energyBar:update(data.waterPercent)
      convertColour(data.waterPercent)
      mon.setCursorPos(15,34)
      mon.write(sUtils.cut(data.water .. "/" .. data.waterMax .. "B",11))
      mon.setCursorPos(2,36)
      mon.write("Hot")
      hotCoolantBar:update(data.steamPercent)
      convertColour(colours.pink,data.steamPercent)
      mon.setCursorPos(15,36)
      mon.write(sUtils.cut(data.steam .. "/" .. data.steamMax .. "B",11))
    else
      mon.setCursorPos(2,14)
      mon.blit("Energy","000000","bbbbbb")
      mon.setCursorPos(20,15)
      mon.blit("KiRF/t","000000","bbbbbb")
      mon.setCursorPos(20,16)
      mon.blit("KiRF/t","000000","bbbbbb")
      -- Draw the actual data
      mon.setCursorPos(14,15)
      mon.setTextColour(colours.white)
      mon.setBackgroundColour(colours.blue)
      mon.write(sUtils.cut(tostring(data.rf),5))
      mon.setCursorPos(14,16)
      mon.write(sUtils.cut(tostring(data.rfLastTick),5))
      -- Draw the difference
      local difString = "-" .. sUtils.cut(tostring(data.rfDifference),3) .. "+"
      mon.setCursorPos(14,17)
      if data.rfDifference < 0 then
        mon.blit(difString,"e0008","bbbbb")
      elseif data.rfDifference > 0 then
        mon.blit(difString,"8000d","bbbbb")
      else
        mon.blit(difString,"80008","bbbbb")
      end
      -- Draw the progress bars
      mon.setCursorPos(2,34)
      mon.write("Buffer")
      energyBar:update(data.bufferPercentage)
      convertColour(colours.pink,data.bufferPercentage)
      -- Draw the numbers -- Gonna abuse the free space at the bottom to have more room for this shit
      local one = toSI(data.rf)
      local two = toSI(data.rfMax)
      local str = sUtils.cut(one .. "/" .. two,23)
      mon.setCursorPos(2,36)
      mon.write(str)
    end
    -- Now draw all the progress bars 
    -- Setup progress bars
    -- Colour lookup:
    -- colours.orange: control rod bar 
    -- colour.magenta: fuel bar
    -- colours.lightBlue: waste bar 
    -- colours.yellow: case heat bar 
    -- colours.lime: fuel heat bar 
    -- colours.pink: energy/cold coolant bar 
    -- colours.cyan: hot coolant bar 
    -- Fuel bar! 
    fuelBar:update(data.fuelPercent)
    convertColour(colours.magenta,data.fuelPercent)
    wasteBar:update(data.wastePercent)
    convertColour(colours.lightBlue,data.wastePercent)
    caseHeatBar:update(data.caseTempPercent)
    convertColour(colours.yellow,data.caseTempPercent)
    fuelHeatBar:update(data.fuelTempPercent)
    convertColour(colours.lime,data.fuelTempPercent)
    controlBar:update(data.controlRodDepth)
    convertColour(colours.orange,data.controlRodDepth)
    -- Draw the control rod percentage 
    local str = sUtils.cut(data.controlRodDepth .. "%",4)
    mon.setCursorPos(18,8)
    mon.write(str)
  end
end

local function eventMan()
  while true do
    local event = {os.pullEvent()}
    if event[1] == "monitor_touch" and event[2] == peripheral.getName(mon) then
      -- Event manipulation, to feed into `button.executeButtons`.
      local newEvent = {"mouse_click",1,event[3],event[4]}
      button.executeButtons(newEvent)
    elseif event[1] == "key" then
      -- Key got pressed in terminal, lets handle that
      -- A = Activate reactor, D = Disable reactor, R = Restart pc, S = Shutdown pc 
      if event[2] == keys.a then
        reactor.setActive(true) 
      elseif event[2] == keys.d then
        reactor.setActive(false) 
      elseif event[2] == keys.r then 
        os.reboot() 
      elseif event[2] == keys.s then 
        reactor.setActive(false) 
        os.shutdown() 
      end
    end
  end
end

sUtils.asset.drawSkimg(monSkimg,nil,nil,mon)
sUtils.asset.drawSkimg(termSkimg)

parallel.waitForAny(gatherData,drawData,eventMan)
