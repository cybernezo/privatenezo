local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local ALLOWED_USERIDS = {10386158945, 2370015588}
local player = Players.LocalPlayer

local function notify(title, text, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title;
        Text = text;
        Duration = duration or 5;
    })
end

local function isAllowed(id)
    for _, v in pairs(ALLOWED_USERIDS) do
        if v == id then
            return true
        end
    end
    return false
end

if isAllowed(player.UserId) then
    notify("Private Nezo", "Valide User", 5)

    loadstring(game:HttpGet("https://raw.githubusercontent.com/cybernezo/privatenezo/main/private.lua"))()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/cybernezo/privatenezo/main/tpmenu.lua"))()
    loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
else
    notify("Private Nezo", "Invalide User", 5)
end
