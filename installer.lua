local reactorPeripheralType = "bigger-reactor"
term.setBackgroundColour(colours.blue)
term.setTextColour(colours.white)
term.clear()

term.setCursorPos(1,1)
term.write("Checking & downloading libraries...")

-- Check for: sUtils, button, progressBar (.lua)
local sUtils,button
if not fs.exists("sUtils.lua") then
  -- sUtils doesn't exist, download it.
  local lib,err = http.get("https://raw.githubusercontent.com/SkyTheCodeMaster/SkyDocs/ddec75606d183c743c9a92bd08d28b60f8caae3a/src/main/misc/sUtils.lua") -- Collect the sUtils package.
  if not lib then error("sUtils: " .. err) end -- Check if we got a handle, and error if we don't.
  -- We got the library, now write it to file.
  local f = fs.open("sUtils.lua","w") -- Open `sUtils.lua` for writing.
  local content = lib.readAll() lib.close() -- Read and close the web handle.
  f.write(content) -- Write it to the file.
  -- While we're at it, load it into our local sUtils variable.
  sUtils = load(content,"sUtils","t",_ENV)()
else -- Else, just `require` the file.
  sUtils = require("sUtils")
end

if not fs.exists("button.lua") then
  -- button doesn't exist, download it.
  local content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/SkyDocs/ddec75606d183c743c9a92bd08d28b60f8caae3a/src/main/misc/button.lua") -- Collect the button package.
  if not content then error("button: " .. err) end -- Check if we got a handle, and error if we don't.
  -- We got the library, now write it to file.
  sUtils.fwrite("button.lua",content)
  -- While we're at it, load it into our local button variable.
  button = load(content,"sUtils","t",_ENV)()
else -- Else, just `require` the file.
  button = require("button")
end

if not fs.exists("progressBar.lua") then
  -- progressBar doesn't exist, download it.
  local content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/SkyDocs/ddec75606d183c743c9a92bd08d28b60f8caae3a/src/main/misc/progressbar.lua") -- Collect the progress bar package.
  if not content then error("pg: " .. err) end -- Check if we got a handle, and error if we don't.
  -- We got the library, now write it to file.
  sUtils.fwrite("progressBar.lua",content)
  -- We don't need the progress bar api for this, so we're not gonna load it.
end

term.setCursorPos(1,2)
term.write("Done. Downloading assets.")

-- We don't need to save the installer skimg file, so we can just save it in a local variable.
local content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/cc-reactor-control/main/assets/installer.skimg")
if not content then error("installer.skimg: " .. err) end
local installerSkimg = textutils.unserialize(content)

-- Download the monitor and term skimgs
content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/cc-reactor-control/main/assets/monitor.skimg")
if not content then error("monitor.skimg: " .. err) end
sUtils.fwrite("assets/monitor.skimg",content)

content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/cc-reactor-control/main//assets/terminal.skimg")
if not content then error("terminal.skimg: " .. err) end
sUtils.fwrite("assets/terminal.skimg",content)

term.setCursorPos(1,3)
term.write("Done. Downloading scripts.")

content,err = sUtils.hread("https://raw.githubusercontent.com/SkyTheCodeMaster/cc-reactor-control/main/main.lua")
if not content then error("reactor.lua: " .. err) end
sUtils.fwrite("reactor.lua",content)

local function main()
  term.clear()
  sUtils.asset.drawSkimg(installerSkimg)

  local peripherals = peripheral.getNames()
  local reactors,monitors,config = {},{},{}
  for i=1,#peripherals do
    local pType = peripheral.getType(peripherals[i])
    if pType == reactorPeripheralType then
      table.insert(reactors,peripherals[i])
    elseif pType == "monitor" then
      table.insert(monitors,peripherals[i])
    end
  end

  if #reactors == 0 or #monitors == 0 then
    for i=7,13 do
      term.setCursorPos(13,i) 
      term.blit("                       ","fffffffffffffffffffffff","88888888888888888888888")
    end
    term.setCursorPos(13,7)
    term.blit("No reactors and/or","eeeeeeeeeeeeeeeeee","888888888888888888")
    term.setCursorPos(13,8)
    term.blit("monitors found.","eeeeeeeeeeeeeee","888888888888888")
    term.setCursorPos(13,10)
    term.blit("Attach some, and press","0000000000000000000000","8888888888888888888888")
    term.setCursorPos(13,11)
    term.blit("any key to continue.","00000000000000000000","88888888888888888888")
    os.pullEvent("key")
    return main()
  end
  local rSelected = 1
  local mSelected = 1
  -- Load the first of each type
  term.setTextColour(colours.white)
  term.setBackgroundColour(colours.lightGrey)
  term.setCursorPos(13,8)
  term.write(sUtils.cut(reactors[1],21))
  term.setCursorPos(13,10)
  term.write(sUtils.cut(monitors[1],21))
  -- Reasonably, this part of the code only gets ran once, so we can initalize the buttons here.
  -- I'm not planning to do anything w/ the button, so I can just discard the IDs.
  button.newButton(34,8,1,1,function()
    rSelected = rSelected - 1
    if rSelected <= 0 then
      rSelected = #reactors
    elseif rSelected > #reactors then
      rSelected = 1
    end
    term.setTextColour(colours.white)
    term.setBackgroundColour(colours.lightGrey)
    term.setCursorPos(13,8)
    term.write(sUtils.cut(reactors[1],21))
  end)
  button.newButton(35,8,1,1,function()
    rSelected = rSelected + 1
    if rSelected <= 0 then
      rSelected = #reactors
    elseif rSelected > #reactors then
      rSelected = 1
    end
    term.setTextColour(colours.white)
    term.setBackgroundColour(colours.lightGrey)
    term.setCursorPos(13,8)
    term.write(sUtils.cut(reactors[1],21))
  end)
  button.newButton(34,10,1,1,function()
    mSelected = mSelected - 1
    if rSelected <= 0 then
      mSelected = #monitors
    elseif mSelected > #monitors then
      mSelected = 1
    end
    term.setTextColour(colours.white)
    term.setBackgroundColour(colours.lightGrey)
    term.setCursorPos(13,10)
    term.write(sUtils.cut(monitors[1],21))
  end)
  button.newButton(35,10,1,1,function()
    mSelected = mSelected + 1
    if rSelected <= 0 then
      mSelected = #monitors
    elseif mSelected > #monitors then
      mSelected = 1
    end
    term.setTextColour(colours.white)
    term.setBackgroundColour(colours.lightGrey)
    term.setCursorPos(13,10)
    term.write(sUtils.cut(monitors[1],21))
  end)
  -- Accept config button
  button.newButton(17,12,3,2,function()
    config["reactor"] = reactors[rSelected]
    config["monitor"] = monitors[mSelected]
    sUtils.encfwrite(".reactor.conf",config)
    for i=7,13 do
      term.setCursorPos(13,i) 
      term.blit("                       ","fffffffffffffffffffffff","88888888888888888888888")
    end
    term.setCursorPos(13,7)
    term.blit("Config written.","444444444444444","888888888888888")
    term.setCursorPos(13,8)
    term.blit("Press any key to exit.","4444444444444444444444","8888888888888888888888")
    term.setCursorPos(13,10)
    term.blit("Installed program is","44444444444444444444","88888888888888888888")
    term.setCursorPos(13,11)
    term.blit("called 'reactor.lua'.","444444444444444444444","888888888888888888888")
    os.pullEvent("key")
    term.setBackgroundColour(colours.black)
    term.setTextColour(colours.white)
    term.clear()
    error("Install successful!")
  end)
  -- Cancel installation. This will delete the assets, but keep the libraries (They're useful, mang)
  button.newButton(29,12,3,2,function()
    for i=7,13 do
      term.setCursorPos(13,i) 
      term.blit("                       ","fffffffffffffffffffffff","88888888888888888888888")
    end
    term.setCursorPos(13,7)
    term.blit("Install cancelled.","eeeeeeeeeeeeeeeeee","888888888888888888")
    fs.delete("assets/monitor.skimg")
    fs.delete("assets/terminal.skimg")
    term.setBackgroundColour(colours.black)
    term.setTextColour(colours.white)
    term.clear()
    error("Exited")
  end)
  while true do
    button.executeButtons({os.pullEvent()})
  end
end

main()