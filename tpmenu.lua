local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0,300,0,350)
Frame.Position = UDim2.new(0.5,-150,0.5,-175)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.Active = true
Frame.Draggable = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,40)
Title.Text = "TP MENU"
Title.BackgroundColor3 = Color3.fromRGB(45,45,45)
Title.TextColor3 = Color3.new(1,1,1)

local InvisButton = Instance.new("TextButton", Frame)
InvisButton.Size = UDim2.new(1,0,0,30)
InvisButton.Position = UDim2.new(0,0,0,40)
InvisButton.Text = "FULL INVISIBLE"
InvisButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
InvisButton.TextColor3 = Color3.new(1,1,1)

local Scroll = Instance.new("ScrollingFrame", Frame)
Scroll.Size = UDim2.new(1,0,1,-70)
Scroll.Position = UDim2.new(0,0,0,70)
Scroll.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Scroll)

-- INVISIBLE
InvisButton.MouseButton1Click:Connect(function()
	if LocalPlayer.Character then
		for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Transparency = 1
				v.CanCollide = false
			end
		end
	end
end)

-- TP LIST
local function RefreshPlayers()

	for _,v in pairs(Scroll:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end

	for _,player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then

			local Button = Instance.new("TextButton", Scroll)
			Button.Size = UDim2.new(1,-10,0,35)
			Button.Text = "TP TO "..player.Name
			Button.BackgroundColor3 = Color3.fromRGB(50,50,50)
			Button.TextColor3 = Color3.new(1,1,1)

			Button.MouseButton1Click:Connect(function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					LocalPlayer.Character:MoveTo(player.Character.HumanoidRootPart.Position)
				end
			end)

		end
	end

	task.wait()
	Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y)

end

RefreshPlayers()
Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)

-- MENU TOGGLE F8
UIS.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F8 then
		Frame.Visible = not Frame.Visible
	end
end)

-- FLY SYSTEM
local flying = false
local speed = 250

local bv
local bg

local function startFly()

	local char = LocalPlayer.Character
	local hrp = char:WaitForChild("HumanoidRootPart")

	bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(9e9,9e9,9e9)
	bv.Velocity = Vector3.new()
	bv.Parent = hrp

	bg = Instance.new("BodyGyro")
	bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
	bg.CFrame = hrp.CFrame
	bg.Parent = hrp

	RunService.RenderStepped:Connect(function()

		if not flying then return end

		local cam = workspace.CurrentCamera
		bg.CFrame = cam.CFrame

		local move = Vector3.new()

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			move = move + cam.CFrame.LookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.S) then
			move = move - cam.CFrame.LookVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.A) then
			move = move - cam.CFrame.RightVector
		end
		if UIS:IsKeyDown(Enum.KeyCode.D) then
			move = move + cam.CFrame.RightVector
		end

		bv.Velocity = move * speed

	end)

end

local function stopFly()
	if bv then bv:Destroy() end
	if bg then bg:Destroy() end
end

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.F then

		flying = not flying

		if flying then
			startFly()
		else
			stopFly()
		end

	end
end)
