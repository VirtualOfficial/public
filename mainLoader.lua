-- lol ofc id obfuscate this :clown:
getgenv().Tick = tick() -- no, this is not used for any whitelisting shit - it's exclusively to check how long the script took to load so don't even try

local function createMessageBox(code,err)
    -- copied from messageBox.js
    messagebox(("An error occured internally.\n\nError code: %s\nError description: %s\n\n\nIf this occurs consistently, create a ticket in our Discord server."):format(code,err),"GripHook Error",0)
    game:Shutdown()
end

if getgenv().Tick == nil then 
    createMessageBox(101,"Failed to find Tick. Do not execute this script outside of the initial loader.")
end 

local s,initialLoader = pcall(function()
    return syn.request({
        Url = ("http://griphook.xyz:8080/api/hub/v3/auth/%s"):format(getgenv().Key),
        Method = "GET"
    }).Body
end)

if s then 
    local load

    local s, err = pcall(function()
        load = loadstring(initialLoader)
    end)

    if s then 
        load() -- decided to not wrap this in pcall - i want proper error logging.
    else 
        createMessageBox(102,"Failed to load loader (2): " .. err)
    end 
else 
    createMessageBox(102,"Failed to load loader: " .. initialLoader)
end 

