local HttpService = game:GetService("HttpService")


local apiURL = "https://a557c7c2-6cb5-4f9d-9058-fd6fd1169f5d-00-1ejnxq8hexa3b.kirk.replit.dev/api/verify"

local scriptURL = "https://raw.githubusercontent.com/cybernezo/privatenezo/refs/heads/main/private.lua"


local function requestKey()
    local key = ""
    repeat
        key = game:GetService("Players").LocalPlayer:PromptInput("Key; ")
    until key and key ~= ""
    return key
end


local function verifyKey(key)
    local success, result = pcall(function()
        local response = HttpService:PostAsync(apiURL, HttpService:JSONEncode({key = key}), Enum.HttpContentType.ApplicationJson)
        return HttpService:JSONDecode(response)
    end)
    if success and result and result.valid then
        return true
    else
        return false, result and result.message or "Erreur API"
    end
end

local function loadPrivateScript()
    local success, code = pcall(function()
        return game:GetService("HttpService"):GetAsync(scriptURL)
    end)
    if success and code then
        loadstring(code)()
    else
        warn("FAKE")
    end
end

local key = requestKey()
local valid, err = verifyKey(key)
if valid then
    print("Valide Key")
    loadPrivateScript()
else
    warn("Clé invalide : " .. tostring(err))
end
