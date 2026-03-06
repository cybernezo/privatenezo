local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 320, 0, 380)
Frame.Position = UDim2.new(0.5, -160, 0.5, -190)
Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Frame.BackgroundTransparency = 0.35
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true

local Corner = Instance.new("UICorner", Frame)
Corner.CornerRadius = UDim.new(0, 14)

local Stroke = Instance.new("UIStroke", Frame)
Stroke.Color = Color3.fromRGB(60, 60, 60)
Stroke.Thickness = 1.5
Stroke.Transparency = 0.5

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1, 0, 0, 45)
Title.Text = "TP MENU"
Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Title.BackgroundTransparency = 0.5
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.BorderSizePixel = 0
Title.ZIndex = 2

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 14)

local TitleFix = Instance.new("Frame", Frame)
TitleFix.Size = UDim2.new(1, 0, 0, 14)
TitleFix.Position = UDim2.new(0, 0, 0, 31)
TitleFix.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
TitleFix.BackgroundTransparency = 0.5
TitleFix.BorderSizePixel = 0
TitleFix.ZIndex = 2

local SearchBox = Instance.new("TextBox", Frame)
SearchBox.Size = UDim2.new(1, -20, 0, 32)
SearchBox.Position = UDim2.new(0, 10, 0, 52)
SearchBox.PlaceholderText = "Rechercher un joueur..."
SearchBox.Text = ""
SearchBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
SearchBox.BackgroundTransparency = 0.4
SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 13
SearchBox.BorderSizePixel = 0
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 3

local SCorner = Instance.new("UICorner", SearchBox)
SCorner.CornerRadius = UDim.new(0, 8)

local SStroke = Instance.new("UIStroke", SearchBox)
SStroke.Color = Color3.fromRGB(70, 70, 70)
SStroke.Thickness = 1
SStroke.Transparency = 0.4

local SPad = Instance.new("UIPadding", SearchBox)
SPad.PaddingLeft = UDim.new(0, 10)

local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1, -20, 1, -95)
Scroll.Position = UDim2.new(0, 10, 0, 92)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
Scroll.ZIndex = 3

local Layout = Instance.new("UIListLayout", Scroll)
Layout.Padding = UDim.new(0, 6)
Layout.SortOrder = Enum.SortOrder.LayoutOrder

local searchQuery = ""

local function CreatePlayerButton(player)
	local Button = Instance.new("TextButton", Scroll)
	Button.Size = UDim2.new(1, -4, 0, 38)
	Button.Text = player.Name
	Button.TextXAlignment = Enum.TextXAlignment.Left
	Button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Button.BackgroundTransparency = 0.45
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.Font = Enum.Font.Gotham
	Button.TextSize = 13
	Button.BorderSizePixel = 0
	Button.ZIndex = 4
	Button.Name = player.Name

	local BCorner = Instance.new("UICorner", Button)
	BCorner.CornerRadius = UDim.new(0, 8)

	local BStroke = Instance.new("UIStroke", Button)
	BStroke.Color = Color3.fromRGB(70, 70, 70)
	BStroke.Thickness = 1
	BStroke.Transparency = 0.5

	local BPad = Instance.new("UIPadding", Button)
	BPad.PaddingLeft = UDim.new(0, 12)

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.12), {BackgroundTransparency = 0.2}):Play()
	end)
	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.12), {BackgroundTransparency = 0.45}):Play()
	end)

	Button.MouseButton1Click:Connect(function()
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character:MoveTo(player.Character.HumanoidRootPart.Position)
			TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
			task.wait(0.15)
			TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.45}):Play()
		end
	end)

	return Button
end

local function RefreshPlayers()
	for _, v in pairs(Scroll:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local name = player.Name:lower()
			if searchQuery == "" or name:find(searchQuery:lower(), 1, true) then
				CreatePlayerButton(player)
			end
		end
	end
	task.wait()
	Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 6)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = SearchBox.Text
	RefreshPlayers()
end)

RefreshPlayers()
Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F8 then
		if Frame.Visible then
			TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
			task.wait(0.2)
			Frame.Visible = false
		else
			Frame.Visible = true
			Frame.BackgroundTransparency = 1
			TweenService:Create(Frame, TweenInfo.new(0.2), {BackgroundTransparency = 0.35}):Play()
		end
	end
end)

local flying = false
local speed = 250
local bv, bg

local function startFly()
	local char = LocalPlayer.Character
	local hrp = char:WaitForChild("HumanoidRootPart")
	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	bv.Velocity = Vector3.new()
	bv.Parent = hrp
	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp
	RunService.RenderStepped:Connect(function()
		if not flying then return end
		local cam = workspace.CurrentCamera
		bg.CFrame = cam.CFrame
		local move = Vector3.new()
		if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + cam.CFrame.RightVector end
		bv.Velocity = move * speed
	end)
end

local function stopFly()
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end
end

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		flying = not flying
		if flying then startFly() else stopFly() end
	end
end)
