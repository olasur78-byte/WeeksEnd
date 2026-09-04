-- Replace MonsterToggle with this LocalScript.
-- Put it in StarterPlayer > StarterPlayerScripts (NOT StarterCharacterScripts).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local toggleRemote = remotes:WaitForChild("ToggleMonsterForm")
local roleAssignedRemote = remotes:WaitForChild("RoleAssigned")
local roundStateRemote = remotes:WaitForChild("RoundStateChanged")
local getMyRole = remotes:WaitForChild("GetMyRole")

local COOLDOWN_SECONDS = 8
local isKidnapper = false
local isMonsterForm = false
local coolingDown = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MonsterTransformUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -24, 1, -32)
panel.Size = UDim2.fromOffset(280, 116)
panel.BackgroundColor3 = Color3.fromRGB(24, 18, 38)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(184, 84, 255)
stroke.Thickness = 2
stroke.Parent = panel

local monsterLabel = Instance.new("TextLabel")
monsterLabel.BackgroundTransparency = 1
monsterLabel.Position = UDim2.fromOffset(12, 8)
monsterLabel.Size = UDim2.new(1, -24, 0, 28)
monsterLabel.Font = Enum.Font.GothamBold
monsterLabel.TextColor3 = Color3.fromRGB(238, 214, 255)
monsterLabel.TextSize = 18
monsterLabel.TextXAlignment = Enum.TextXAlignment.Left
monsterLabel.Parent = panel

local transformButton = Instance.new("TextButton")
transformButton.Position = UDim2.fromOffset(12, 44)
transformButton.Size = UDim2.new(1, -24, 0, 58)
transformButton.BackgroundColor3 = Color3.fromRGB(123, 46, 184)
transformButton.BorderSizePixel = 0
transformButton.Font = Enum.Font.GothamBold
transformButton.TextColor3 = Color3.new(1, 1, 1)
transformButton.TextSize = 17
transformButton.Parent = panel
Instance.new("UICorner", transformButton).CornerRadius = UDim.new(0, 8)

local function readyText()
	return isMonsterForm and "PRESS G TO RETURN TO CIVILIAN" or "PRESS G TO TRANSFORM"
end

local function showForKidnapper(monsterId)
	if not monsterId then
		return
	end
	isKidnapper = true
	monsterLabel.Text = "YOUR BEAST: " .. monsterId:gsub("(%l)(%u)", "%1 %2"):upper()
	transformButton.Text = readyText()
	panel.Visible = true
end

local function requestTransform()
	if not isKidnapper or coolingDown then
		return
	end
	toggleRemote:FireServer()
	isMonsterForm = not isMonsterForm
	coolingDown = true
	task.spawn(function()
		for seconds = COOLDOWN_SECONDS, 1, -1 do
			transformButton.Text = "ABILITY READY IN " .. seconds .. "s"
			transformButton.BackgroundColor3 = Color3.fromRGB(69, 54, 86)
			task.wait(1)
		end
		coolingDown = false
		transformButton.BackgroundColor3 = Color3.fromRGB(123, 46, 184)
		transformButton.Text = readyText()
	end)
end

transformButton.Activated:Connect(requestTransform)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.G then
		requestTransform()
	end
end)

roleAssignedRemote.OnClientEvent:Connect(function(role, monsterId)
	if role == "Kidnapper" then
		showForKidnapper(monsterId)
	end
end)

-- This makes the UI reliable even if RoleAssigned was sent before the LocalScript loaded.
roundStateRemote.OnClientEvent:Connect(function(state)
	if state == "RoundStarted" then
		local role, monsterId = getMyRole:InvokeServer()
		if role == "Kidnapper" then
			showForKidnapper(monsterId)
		end
	end
end)
