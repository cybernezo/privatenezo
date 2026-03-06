local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local LP             = Players.LocalPlayer
local Camera         = workspace.CurrentCamera

local FlySpeed  = 60
local MenuKey   = Enum.KeyCode.RightShift

local flyEnabled  = false
local espEnabled  = false
local flyConn     = nil
local espObjects  = {}
local tpBusy      = false

local BONES_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
    {"Left Arm","Left Leg"},{"Right Arm","Right Leg"},
}
local BONES_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local function drawBones(char)
    local bones = char:FindFirstChild("UpperTorso") and BONES_R15 or BONES_R6
    local lines = {}
    for _, pair in ipairs(bones) do
        local partA = char:FindFirstChild(pair[1])
        local partB = char:FindFirstChild(pair[2])
        if partA and partB then
            local line = Instance.new("LineHandleAdornment")
            line.Thickness  = 2
            line.Color3     = Color3.fromRGB(255, 255, 60)
            line.AlwaysOnTop = true
            line.ZIndex     = 5
            line.Length     = 0
            line.Adornee    = partA
            line.Parent     = partA
            table.insert(lines, {line=line, a=partA, b=partB})
        end
    end
    return lines
end

local function updateBones(lines)
    for _, d in ipairs(lines) do
        if d.line and d.line.Parent and d.a.Parent and d.b.Parent then
            local diff = d.b.Position - d.a.Position
            local dist = diff.Magnitude
            if dist > 0 then
                d.line.Length = dist
                d.line.CFrame = CFrame.new(Vector3.zero, diff.Unit)
            end
        end
    end
end

local ESPFolder
pcall(function()
    ESPFolder = LP.PlayerGui:FindFirstChild("ESPFolder")
    if not ESPFolder then
        ESPFolder = Instance.new("Folder")
        ESPFolder.Name = "ESPFolder"
        ESPFolder.Parent = LP.PlayerGui
    end
end)
if not ESPFolder then
    ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "ESPFolder"
    ESPFolder.Parent = LP.PlayerGui
end

local function removeESP(player)
    if not espObjects[player] then return end
    local folder = ESPFolder:FindFirstChild("ESP_"..player.Name)
    if folder then pcall(function() folder:Destroy() end) end
    if espObjects[player].bones then
        for _, d in ipairs(espObjects[player].bones) do
            pcall(function() d.line:Destroy() end)
        end
    end
    espObjects[player] = nil
end

local function addESP(player)
    if player == LP then return end
    removeESP(player)
    espObjects[player] = {}
    local function applyToChar(char)
        if not char then return end
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not hrp then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        local folder = Instance.new("Folder")
        folder.Name = "ESP_"..player.Name
        folder.Parent = ESPFolder
        local hl = Instance.new("Highlight")
        hl.Name = "HL_"..player.Name
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(255,30,30)
        hl.OutlineColor = Color3.fromRGB(0,220,255)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = folder
        espObjects[player].hl = hl
        local bb = Instance.new("BillboardGui")
        bb.Name = "BB_"..player.Name
        bb.Size = UDim2.new(0,120,0,58)
        bb.StudsOffset = Vector3.new(0,3.2,0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Adornee = head or hrp
        bb.Parent = folder
        local nameLbl = Instance.new("TextLabel", bb)
        nameLbl.Size = UDim2.new(1,0,0,18)
        nameLbl.Position = UDim2.new(0,0,0,0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = player.Name
        nameLbl.TextColor3 = Color3.new(1,1,1)
        nameLbl.TextStrokeTransparency = 0
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 13
        local distLbl = Instance.new("TextLabel", bb)
        distLbl.Size = UDim2.new(1,0,0,14)
        distLbl.Position = UDim2.new(0,0,0,18)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "0m"
        distLbl.TextColor3 = Color3.fromRGB(100,255,150)
        distLbl.TextStrokeTransparency = 0
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextSize = 11
        local hpBg = Instance.new("Frame", bb)
        hpBg.Size = UDim2.new(1,0,0,9)
        hpBg.Position = UDim2.new(0,0,0,35)
        hpBg.BackgroundColor3 = Color3.fromRGB(40,8,8)
        hpBg.BorderSizePixel = 0
        Instance.new("UICorner", hpBg).CornerRadius = UDim.new(1,0)
        local hpFill = Instance.new("Frame", hpBg)
        hpFill.Size = UDim2.new(1,0,1,0)
        hpFill.BackgroundColor3 = Color3.fromRGB(50,255,80)
        hpFill.BorderSizePixel = 0
        Instance.new("UICorner", hpFill).CornerRadius = UDim.new(1,0)
        local hpTxt = Instance.new("TextLabel", hpBg)
        hpTxt.Size = UDim2.new(1,0,1,0)
        hpTxt.BackgroundTransparency = 1
        hpTxt.TextColor3 = Color3.new(1,1,1)
        hpTxt.TextStrokeTransparency = 0
        hpTxt.Font = Enum.Font.GothamBold
        hpTxt.TextSize = 7
        hpTxt.Text = "100/100"
        espObjects[player].distLbl = distLbl
        espObjects[player].hpFill  = hpFill
        espObjects[player].hpTxt   = hpTxt
        espObjects[player].hum     = hum
        local boneLines = drawBones(char)
        espObjects[player].bones = boneLines
    end
    applyToChar(player.Character)
    player.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        if espEnabled then applyToChar(c) end
    end)
end

RunService.Heartbeat:Connect(function()
    if not espEnabled then return end
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    for player, data in pairs(espObjects) do
        local c = player.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if data.distLbl and r and myRoot then
            local d = math.floor((r.Position - myRoot.Position).Magnitude)
            data.distLbl.Text = d.."m"
        end
        if data.hum and data.hpFill then
            local hp  = data.hum.Health
            local mx  = math.max(data.hum.MaxHealth, 1)
            local pct = math.clamp(hp/mx, 0, 1)
            data.hpFill.Size = UDim2.new(pct,0,1,0)
            data.hpFill.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct))+50, math.floor(255*pct)+50, 50)
            if data.hpTxt then data.hpTxt.Text = math.floor(hp).."/"..math.floor(mx) end
        end
        if data.bones then updateBones(data.bones) end
    end
end)

local function startFly()
    if flyConn then pcall(function() flyConn:Disconnect() end); flyConn = nil end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    hum.PlatformStand = true
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e6,1e6,1e6); bv.Velocity = Vector3.zero; bv.Parent = hrp
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e6,1e6,1e6); bg.P = 5000; bg.CFrame = hrp.CFrame; bg.Parent = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyEnabled then
            pcall(function() bv:Destroy() end); pcall(function() bg:Destroy() end)
            pcall(function() hum.PlatformStand = false end)
            flyConn:Disconnect(); flyConn = nil; return
        end
        local cf = Camera.CFrame; local vel = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)            then vel += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)            then vel -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)            then vel -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)            then vel += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)        then vel += Vector3.yAxis  end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)  then vel -= Vector3.yAxis  end
        bv.Velocity = vel.Magnitude > 0 and vel.Unit * FlySpeed or Vector3.zero
        bg.CFrame = cf
    end)
end

local noclipEnabled = false
local noclipConn    = nil

local function startNoclip()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    flyEnabled = true; startFly()
    local function applyNoclip(c)
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.CanCollide = false; p.Transparency = math.max(p.Transparency, 0.6)
            end
        end
        if hrp then hrp.CanCollide = false end
    end
    applyNoclip(char)
    noclipConn = RunService.Stepped:Connect(function()
        if not noclipEnabled then noclipConn:Disconnect(); noclipConn = nil; return end
        local c = LP.Character
        if not c then return end
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    noclipEnabled = false; flyEnabled = false
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = true
            if p.Name ~= "HumanoidRootPart" then p.Transparency = 0 end
        end
    end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false; hum.WalkSpeed = 60; hum.JumpHeight = 7.2 end
end

local function bypassTP(targetCFrame)
    if tpBusy then return false, "TP en cours" end
    local myChar = LP.Character
    if not myChar then return false, "Pas de char" end
    local hrp = myChar:FindFirstChild("HumanoidRootPart")
    local hum = myChar:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false, "HRP manquant" end
    tpBusy = true
    local wasFly = flyEnabled
    if wasFly then flyEnabled = false; task.wait(0.06) end
    for _, v in ipairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") or v:IsA("BodyPosition") then v:Destroy() end
    end
    local oldWalk = hum.WalkSpeed; local oldJump = hum.JumpHeight
    hum.WalkSpeed = 0; hum.JumpHeight = 0; hum.PlatformStand = true
    local origin = hrp.Position
    local dest   = targetCFrame.Position + Vector3.new(0,3.2,0)
    local dist   = (dest - origin).Magnitude
    local stepSize = math.random(40,60)
    local steps    = math.max(2, math.ceil(dist/stepSize))
    local bp = Instance.new("BodyPosition")
    bp.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    bp.P = 2e5; bp.D = 800; bp.Position = origin; bp.Parent = hrp
    local bgyro = Instance.new("BodyGyro")
    bgyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
    bgyro.P = 5000; bgyro.CFrame = hrp.CFrame; bgyro.Parent = hrp
    for i = 1, steps do
        local alpha = i/steps
        local arc   = math.sin(alpha*math.pi) * math.min(dist*0.08, 15)
        local step  = origin:Lerp(dest, alpha) + Vector3.new(0, arc, 0)
        bp.Position = step
        pcall(function() hrp.AssemblyLinearVelocity  = Vector3.zero end)
        pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
        local delay = (steps <= 3) and 0.035 or (math.random(25,50)/1000)
        task.wait(delay)
    end
    bp.Position = dest
    pcall(function() hrp.AssemblyLinearVelocity  = Vector3.zero end)
    pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
    task.wait(0.08)
    hrp.CFrame = CFrame.new(dest) * (targetCFrame - targetCFrame.Position)
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    task.wait(0.05)
    bp:Destroy(); bgyro:Destroy()
    hum.WalkSpeed = oldWalk; hum.JumpHeight = oldJump; hum.PlatformStand = false
    if wasFly then flyEnabled = true; task.wait(0.05); startFly() end
    tpBusy = false
    return true
end

local function tpRandom()
    if tpBusy then return false, "TP déjà en cours" end
    local pool = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(pool, p)
        end
    end
    if #pool == 0 then return false, "Aucun joueur" end
    local target = pool[math.random(#pool)]
    local cf     = target.Character.HumanoidRootPart.CFrame
    task.spawn(function() bypassTP(cf) end)
    return true, "→ "..target.Name
end

local killData = { lastDead="—", lastKilledMe="—", myDeaths=0 }

local function watchDeaths()
    local function watchPlayer(player)
        if player == LP then
            local function onCharAdded(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if not hum then return end
                hum.Died:Connect(function()
                    killData.myDeaths += 1
                    local tag = hum:FindFirstChild("creator")
                    if tag then
                        local killer = tag:FindFirstChild("Value")
                        if killer and killer.Value then killData.lastKilledMe = tostring(killer.Value) end
                    end
                end)
            end
            if player.Character then onCharAdded(player.Character) end
            player.CharacterAdded:Connect(onCharAdded)
        else
            local function onCharAdded(char)
                local hum = char:WaitForChild("Humanoid", 5)
                if not hum then return end
                hum.Died:Connect(function() killData.lastDead = player.Name end)
            end
            if player.Character then onCharAdded(player.Character) end
            player.CharacterAdded:Connect(onCharAdded)
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do watchPlayer(p) end
    Players.PlayerAdded:Connect(watchPlayer)
end
watchDeaths()

local spawnedEntities = {}

local function destroyAllEntities()
    for _, e in ipairs(spawnedEntities) do pcall(function() e:Destroy() end) end
    spawnedEntities = {}
end

local function buildEntity(pos, entityType)
    local model = Instance.new("Model")
    model.Name = "👾_Entity_"..entityType
    local function addPart(name, size, color, cf, transparency)
        local p = Instance.new("Part", model)
        p.Name = name; p.Size = size; p.BrickColor = BrickColor.new(color)
        p.Material = Enum.Material.Neon; p.Anchored = true
        p.CanCollide = false; p.CastShadow = false
        p.Transparency = transparency or 0; p.CFrame = cf
        return p
    end
    local basePos = CFrame.new(pos)
    if entityType == "shadow" then
        local torso = addPart("Torso",Vector3.new(1,1.5,0.5),"Really black",basePos*CFrame.new(0,2,0))
        addPart("Head",Vector3.new(0.9,0.9,0.9),"Really black",basePos*CFrame.new(0,3.2,0))
        addPart("LArm",Vector3.new(0.4,1.2,0.4),"Really black",basePos*CFrame.new(-0.8,2.1,0))
        addPart("RArm",Vector3.new(0.4,1.2,0.4),"Really black",basePos*CFrame.new(0.8,2.1,0))
        addPart("LLeg",Vector3.new(0.45,1.2,0.45),"Really black",basePos*CFrame.new(-0.3,0.9,0))
        addPart("RLeg",Vector3.new(0.45,1.2,0.45),"Really black",basePos*CFrame.new(0.3,0.9,0))
        addPart("EyeL",Vector3.new(0.2,0.2,0.1),"Crimson",basePos*CFrame.new(-0.2,3.25,-0.45))
        addPart("EyeR",Vector3.new(0.2,0.2,0.1),"Crimson",basePos*CFrame.new(0.2,3.25,-0.45))
        model.PrimaryPart = torso
    elseif entityType == "glitch" then
        local torso = addPart("Torso",Vector3.new(1.2,1.8,0.4),"Magenta",basePos*CFrame.new(0,2,0))
        addPart("Head",Vector3.new(1.0,1.0,0.6),"Hot pink",basePos*CFrame.new(0.15,3.3,0.1))
        addPart("F1",Vector3.new(0.5,0.5,0.3),"Magenta",basePos*CFrame.new(-1.2,2.5,0.2)*CFrame.Angles(0.3,0.5,0.2))
        addPart("F2",Vector3.new(0.4,0.8,0.3),"Hot pink",basePos*CFrame.new(1.1,1.8,-0.3)*CFrame.Angles(-0.2,0.8,-0.3))
        addPart("EyeL",Vector3.new(0.3,0.15,0.1),"Cyan",basePos*CFrame.new(-0.2,3.35,-0.3))
        addPart("EyeR",Vector3.new(0.3,0.15,0.1),"Cyan",basePos*CFrame.new(0.35,3.35,-0.3))
        model.PrimaryPart = torso
    elseif entityType == "skeleton" then
        local torso = addPart("Torso",Vector3.new(0.8,1.4,0.3),"White",basePos*CFrame.new(0,2,0))
        addPart("Head",Vector3.new(0.75,0.75,0.7),"White",basePos*CFrame.new(0,3.1,0))
        addPart("LArm",Vector3.new(0.25,1.0,0.25),"White",basePos*CFrame.new(-0.65,2.2,0))
        addPart("RArm",Vector3.new(0.25,1.0,0.25),"White",basePos*CFrame.new(0.65,2.2,0))
        addPart("LLeg",Vector3.new(0.28,1.1,0.28),"White",basePos*CFrame.new(-0.25,0.85,0))
        addPart("RLeg",Vector3.new(0.28,1.1,0.28),"White",basePos*CFrame.new(0.25,0.85,0))
        addPart("Eye1",Vector3.new(0.22,0.22,0.1),"Really black",basePos*CFrame.new(-0.18,3.15,-0.35))
        addPart("Eye2",Vector3.new(0.22,0.22,0.1),"Really black",basePos*CFrame.new(0.18,3.15,-0.35))
        model.PrimaryPart = torso
    end
    model.Parent = workspace
    return model
end

local function spawnEntitiesAt(targetPlayer)
    destroyAllEntities()
    local origin
    if targetPlayer then
        local c = targetPlayer.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if not r then return false, "Char introuvable" end
        origin = r.Position
    else
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        origin = r and r.Position or Vector3.new(0,5,0)
    end
    local types = {"shadow","glitch","skeleton","shadow","glitch","skeleton"}
    local connections = {}
    for i, etype in ipairs(types) do
        local angle = (i/#types)*math.pi*2
        local dist  = 6
        local spawnPos = origin + Vector3.new(math.cos(angle)*dist, 0, math.sin(angle)*dist)
        local entity = buildEntity(spawnPos, etype)
        table.insert(spawnedEntities, entity)
        local t0 = tick()+(i*0.5); local baseAngle = angle
        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not entity or not entity.Parent then conn:Disconnect(); return end
            local t = tick(); local elapsed = t - t0
            local center = origin
            if targetPlayer and targetPlayer.Character then
                local r2 = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if r2 then center = r2.Position end
            end
            local a = baseAngle + elapsed*0.8
            local bob = math.sin(elapsed*2+i)*0.4
            local newPos = center + Vector3.new(math.cos(a)*dist, bob, math.sin(a)*dist)
            pcall(function()
                entity:SetPrimaryPartCFrame(CFrame.new(newPos)*CFrame.Angles(0, a+math.pi, 0))
            end)
        end)
        table.insert(connections, conn)
    end
    task.delay(30, function()
        for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
        destroyAllEntities()
    end)
    return true, #types.." entités (30s)"
end

local freeCamEnabled = false
local freeCamConn    = nil
local freeCamSpeed   = 30
local camCF          = CFrame.new(0,10,0)
local freeCamPitch   = 0
local freeCamYaw     = 0
local fcFreezeConn   = nil
local fcFrozenPos    = nil
local fcOldWalk      = 16
local fcOldJump      = 7.2
local fcFreezeHRP    = nil
local SoundService = game:GetService("SoundService")
local fcAudioConn  = nil

local function startFreeCam()
    freeCamEnabled = true
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hrp and hum then
        fcOldWalk = hum.WalkSpeed; fcOldJump = hum.JumpHeight
        fcFrozenPos = hrp.CFrame
        hum.WalkSpeed = 0; hum.JumpHeight = 0; hum.PlatformStand = true
        for _, v in ipairs(hrp:GetChildren()) do
            if v:IsA("BodyPosition") or v:IsA("BodyVelocity") then v:Destroy() end
        end
        local bp = Instance.new("BodyPosition")
        bp.Name = "FCFreeze"; bp.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
        bp.P = 2e5; bp.D = 1000; bp.Position = hrp.Position; bp.Parent = hrp
        fcFreezeHRP = bp
        fcFreezeConn = RunService.Heartbeat:Connect(function()
            if not freeCamEnabled then return end
            local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if h and fcFreezeHRP and fcFreezeHRP.Parent then
                fcFreezeHRP.Position = fcFrozenPos.Position
                pcall(function() h.AssemblyLinearVelocity  = Vector3.zero end)
                pcall(function() h.AssemblyAngularVelocity = Vector3.zero end)
            end
        end)
    end
    pcall(function()
        SoundService.RespectFilteringEnabled = true
        SoundService.ListenerType = Enum.ListenerType.ObjectCFrame
    end)
    local listenerPart = Instance.new("Part")
    listenerPart.Name = "FCListenerPart"; listenerPart.Anchored = true
    listenerPart.CanCollide = false; listenerPart.CanTouch = false
    listenerPart.Transparency = 1; listenerPart.Size = Vector3.new(0.1,0.1,0.1)
    listenerPart.CFrame = camCF; listenerPart.Parent = workspace
    pcall(function() SoundService.ListenerLocation = listenerPart end)
    local lastEmitterCheck = 0; local voiceSpoofPart = nil
    local function findAudioEmitter(root)
        if not root then return nil end
        local em = root:FindFirstChildOfClass("AudioEmitter")
        if em then return em, root end
        for _, att in ipairs(root:GetChildren()) do
            if att:IsA("Attachment") then
                local e2 = att:FindFirstChildOfClass("AudioEmitter")
                if e2 then return e2, att end
            end
        end
        return nil, nil
    end
    local function setupVoiceSpoof(root)
        if voiceSpoofPart and voiceSpoofPart.Parent then voiceSpoofPart:Destroy(); voiceSpoofPart = nil end
        local emitter, emParent = findAudioEmitter(root)
        if not emitter then return end
        local vp = Instance.new("Part")
        vp.Name = "VoiceSpoofPart"; vp.Anchored = true
        vp.CanCollide = false; vp.CanTouch = false
        vp.Transparency = 1; vp.Size = Vector3.new(0.1,0.1,0.1)
        vp.CFrame = camCF; vp.Parent = root
        voiceSpoofPart = vp
        pcall(function() emParent.Parent = vp end)
    end
    fcAudioConn = RunService.Heartbeat:Connect(function()
        if not freeCamEnabled then return end
        if listenerPart and listenerPart.Parent then
            listenerPart.CFrame = camCF
            pcall(function() SoundService.ListenerLocation = listenerPart end)
        end
        local now = tick()
        if now - lastEmitterCheck > 1.0 then
            lastEmitterCheck = now
            local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if h then
                if not voiceSpoofPart or not voiceSpoofPart.Parent then setupVoiceSpoof(h) end
            end
        end
        if voiceSpoofPart and voiceSpoofPart.Parent then voiceSpoofPart.CFrame = camCF end
    end)
    local initHRP = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if initHRP then setupVoiceSpoof(initHRP) end
    camCF = Camera.CFrame
    freeCamYaw   = math.atan2(-camCF.LookVector.X, -camCF.LookVector.Z)
    freeCamPitch = math.asin(math.clamp(camCF.LookVector.Y, -1, 1))
    Camera.CameraType = Enum.CameraType.Scriptable
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    UserInputService.MouseIconEnabled = false
    local lastTime = tick()
    freeCamConn = RunService.RenderStepped:Connect(function()
        if not freeCamEnabled then return end
        local dt = tick() - lastTime; lastTime = tick()
        local delta = UserInputService:GetMouseDelta()
        freeCamYaw   = freeCamYaw   - delta.X * 0.003
        freeCamPitch = math.clamp(freeCamPitch - delta.Y * 0.003, -math.pi/2+0.05, math.pi/2-0.05)
        local rot = CFrame.Angles(0, freeCamYaw, 0) * CFrame.Angles(freeCamPitch, 0, 0)
        local lookVec = rot.LookVector; local rightVec = rot.RightVector
        local speed = freeCamSpeed
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then speed = speed * 3 end
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then move += lookVec  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then move -= lookVec  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then move -= rightVec end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then move += rightVec end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then move += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q)           then move -= Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.yAxis end
        if move.Magnitude > 0 then
            camCF = CFrame.new(camCF.Position + move.Unit * speed * dt) * rot
        else
            camCF = CFrame.new(camCF.Position) * rot
        end
        Camera.CFrame = camCF
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not freeCamEnabled then return end
        if inp.UserInputType == Enum.UserInputType.MouseWheel then
            freeCamSpeed = math.clamp(freeCamSpeed + inp.Position.Z * 5, 5, 200)
        end
    end)
end

local function stopFreeCam()
    freeCamEnabled = false
    if freeCamConn  then freeCamConn:Disconnect();  freeCamConn  = nil end
    if fcFreezeConn then fcFreezeConn:Disconnect(); fcFreezeConn = nil end
    if fcAudioConn  then fcAudioConn:Disconnect();  fcAudioConn  = nil end
    if fcFreezeHRP and fcFreezeHRP.Parent then fcFreezeHRP:Destroy(); fcFreezeHRP = nil end
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = fcOldWalk; hum.JumpHeight = fcOldJump; hum.PlatformStand = false end
    pcall(function() SoundService.ListenerType = Enum.ListenerType.Camera end)
    pcall(function()
        local lp = workspace:FindFirstChild("FCListenerPart")
        if lp then lp:Destroy() end
    end)
    pcall(function()
        local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if h then
            local vp = h:FindFirstChild("VoiceSpoofPart")
            if vp then
                local att = vp:FindFirstChildOfClass("Attachment")
                if att then att.Parent = h end
                vp:Destroy()
            end
        end
    end)
    Camera.CameraType = Enum.CameraType.Custom
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
end


pcall(function() LP.PlayerGui:FindFirstChild("LocalMenu"):Destroy() end)
pcall(function()
    local cg = game:GetService("CoreGui")
    if cg:FindFirstChild("LocalMenu") then cg:FindFirstChild("LocalMenu"):Destroy() end
end)

local function getStreamProofParent()
    if typeof(gethui) == "function" then return gethui() end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then return cg end
    return LP:WaitForChild("PlayerGui")
end

local Gui = Instance.new("ScreenGui")
Gui.Name             = "LocalMenu"
Gui.ResetOnSpawn     = false
Gui.DisplayOrder     = 999
Gui.IgnoreGuiInset   = true
Gui.ZIndexBehavior   = Enum.ZIndexBehavior.Global
Gui.Parent           = getStreamProofParent()

local Frame = Instance.new("Frame")
Frame.Size             = UDim2.new(0, 230, 0, 0)  
Frame.Position         = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.45
Frame.BorderSizePixel  = 0
Frame.Active           = true
Frame.ClipsDescendants = true
Frame.Parent           = Gui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

local layout = Instance.new("UIListLayout", Frame)
layout.Padding    = UDim.new(0, 0)
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder  = Enum.SortOrder.LayoutOrder

local padding = Instance.new("UIPadding", Frame)
padding.PaddingTop    = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft   = UDim.new(0, 10)
padding.PaddingRight  = UDim.new(0, 10)

-- Drag du carré
local dragging, dragStart, frameStart = false, nil, nil
Frame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = inp.Position; frameStart = Frame.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local d = inp.Position - dragStart
        Frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset+d.X,
                                    frameStart.Y.Scale, frameStart.Y.Offset+d.Y)
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local ROW_H = 28
local function makeRow()
    local r = Instance.new("Frame")
    r.Size             = UDim2.new(1, 0, 0, ROW_H)
    r.BackgroundTransparency = 1
    r.BorderSizePixel  = 0
    r.LayoutOrder      = 0
    r.Parent           = Frame
    return r
end

local function makeSep(order)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    s.BackgroundTransparency = 0.5
    s.BorderSizePixel = 0
    s.LayoutOrder = order
    s.Parent = Frame
end

local function makeLabel(txt, order)
    local r = makeRow()
    r.LayoutOrder = order
    r.Size = UDim2.new(1, 0, 0, 18)
    local l = Instance.new("TextLabel", r)
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.fromRGB(120, 120, 120)
    l.Font = Enum.Font.Gotham
    l.TextSize = 9
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 2
end

local function makeToggle(txt, order, cb)
    local r = makeRow()
    r.LayoutOrder = order

    local lbl = Instance.new("TextLabel", r)
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3

    local dot = Instance.new("Frame", r)
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(1, -10, 0.5, -4)
    dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    dot.BorderSizePixel = 0
    dot.ZIndex = 3
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton", r)
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 4

    local isOn = false
    local function sv(on)
        isOn = on
        if on then
            dot.BackgroundColor3 = Color3.fromRGB(80, 255, 80)
            lbl.TextColor3 = Color3.new(1, 1, 1)
        else
            dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    btn.MouseButton1Click:Connect(function()
        sv(not isOn); cb(isOn)
    end)
    return sv 
end

-- Action : bouton texte simple
local function makeAction(txt, order, cb)
    local r = makeRow()
    r.LayoutOrder = order

    local lbl = Instance.new("TextLabel", r)
    lbl.Size = UDim2.new(1, -32, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 3

    local go = Instance.new("TextButton", r)
    go.Size = UDim2.new(0, 26, 0, 18)
    go.Position = UDim2.new(1, -28, 0.5, -9)
    go.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    go.BackgroundTransparency = 0.3
    go.Text = "▶"
    go.TextColor3 = Color3.fromRGB(180, 180, 180)
    go.Font = Enum.Font.Gotham
    go.TextSize = 10
    go.BorderSizePixel = 0
    go.ZIndex = 4
    Instance.new("UICorner", go).CornerRadius = UDim.new(0, 3)

    go.MouseButton1Click:Connect(function()
        local ok, msg = cb()
        lbl.Text = ok and ("✓ "..txt) or ("✗ "..txt)
        lbl.TextColor3 = ok and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)
        task.delay(2.5, function()
            lbl.Text = txt
            lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
    end)
end


makeLabel("VISUEL", 1)
makeToggle("ESP ", 2, function(on)
    espEnabled = on
    if on then
        for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
        Players.PlayerAdded:Connect(function(p)
            if espEnabled then task.wait(0.5); addESP(p) end
        end)
        Players.PlayerRemoving:Connect(removeESP)
    else
        for _, p in ipairs(Players:GetPlayers()) do removeESP(p) end
    end
end)

makeSep(3)
makeLabel("DÉPLACEMENT", 4)
makeToggle("Fly (BASIC)", 5, function(on)
    flyEnabled = on
    if on then startFly() end
end)
makeToggle("Noclip", 6, function(on)
    noclipEnabled = on
    if on then startNoclip() else stopNoclip() end
end)

makeSep(7)
makeLabel("TÉLÉPORTATION", 8)
makeAction("TP RANDOM", 9, tpRandom)

makeSep(10)
makeLabel("CAMÉRA", 11)
local setFreeCamToggle = makeToggle("Free Cam (V)", 12, function(on)
    freeCamEnabled = on
    if on then startFreeCam() else stopFreeCam() end
end)

-- Redimensionne Frame à la taille du contenu
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Frame.Size = UDim2.new(0, 230, 0, layout.AbsoluteContentSize.Y + 14)
end)
Frame.Size = UDim2.new(0, 230, 0, layout.AbsoluteContentSize.Y + 14)

local menuOpen = true
local function toggleMenu()
    menuOpen = not menuOpen
    Frame.Visible = menuOpen
end

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == MenuKey then toggleMenu() end
    if inp.KeyCode == Enum.KeyCode.V then
        freeCamEnabled = not freeCamEnabled
        if freeCamEnabled then startFreeCam() else stopFreeCam() end
        if setFreeCamToggle then setFreeCamToggle(freeCamEnabled) end
    end
end)

-- Respawn
LP.CharacterAdded:Connect(function()
    task.wait(1)
    if flyEnabled then startFly() end
    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do addESP(p) end
    end
    if freeCamEnabled then
        stopFreeCam(); task.wait(0.5); startFreeCam()
    end
end)

print("Private By Nezo")
