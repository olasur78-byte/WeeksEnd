local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local roleAssignedRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("RoleAssigned")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PrivateRoleUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local roleLabel = Instance.new("TextLabel")
roleLabel.AnchorPoint = Vector2.new(0.5, 0)
roleLabel.Position = UDim2.new(0.5, 0, 0, 32)
roleLabel.Size = UDim2.fromOffset(420, 70)
roleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
roleLabel.BackgroundTransparency = 0.15
roleLabel.BorderSizePixel = 0
roleLabel.Font = Enum.Font.GothamBold
roleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
roleLabel.TextSize = 24
roleLabel.TextWrapped = true
roleLabel.Text = "WAITING FOR PLAYERS..."
roleLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = roleLabel

roleAssignedRemote.OnClientEvent:Connect(function(role, monsterId)
	if role == "Kidnapper" then
		roleLabel.Text = "YOUR SECRET ROLE: KIDNAPPER\nBEAST: " .. tostring(monsterId)
		roleLabel.TextColor3 = Color3.fromRGB(255, 112, 112)

	elseif role == "Detective" then
		roleLabel.Text = "YOUR SECRET ROLE: DETECTIVE\nFind the kidnapper."
		roleLabel.TextColor3 = Color3.fromRGB(105, 185, 255)

	elseif role == "Kidnapped" then
		roleLabel.Text = "YOUR SECRET ROLE: KIDNAPPED\nSurvive and escape."
		roleLabel.TextColor3 = Color3.fromRGB(255, 221, 118)
	end
end)