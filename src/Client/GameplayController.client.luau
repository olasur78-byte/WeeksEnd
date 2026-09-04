local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local gui = Instance.new("ScreenGui")
gui.Name = "GameplayStatus"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(0.5, 1)
label.Position = UDim2.new(0.5, 0, 1, -20)
label.Size = UDim2.fromOffset(520, 72)
label.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.new(1, 1, 1)
label.TextWrapped = true
label.Font = Enum.Font.GothamMedium
label.TextSize = 15
label.Visible = false
label.Parent = gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)

local guessFrame = Instance.new("Frame")
guessFrame.Position = UDim2.fromOffset(12, 50)
guessFrame.Size = UDim2.fromOffset(210, 230)
guessFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
guessFrame.Visible = false
guessFrame.Parent = gui
Instance.new("UICorner", guessFrame).CornerRadius = UDim.new(0, 8)
local guessLayout = Instance.new("UIListLayout", guessFrame)
guessLayout.Padding = UDim.new(0, 4)
local monsters = { "NightMoth", "HollowMimic", "AntlerStalker", "ClockworkWarden", "BogWalker", "NeonWisp" }
for _, monsterId in monsters do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, 0, 0, 34)
	button.Text = monsterId:gsub("(%l)(%u)", "%1 %2")
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 14
	button.BackgroundColor3 = Color3.fromRGB(42, 49, 68)
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = guessFrame
	button.Activated:Connect(function()
		local success, message = Remotes.SubmitMonsterGuess:InvokeServer(monsterId)
		label.Visible = true
		label.Text = message
		if success then guessFrame.Visible = false end
	end)
end

local dialogueFrame = Instance.new("Frame")
dialogueFrame.AnchorPoint = Vector2.new(0.5, 0.5)
dialogueFrame.Position = UDim2.fromScale(0.5, 0.5)
dialogueFrame.Size = UDim2.fromOffset(560, 250)
dialogueFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
dialogueFrame.Visible = false
dialogueFrame.Parent = gui
Instance.new("UICorner", dialogueFrame).CornerRadius = UDim.new(0, 8)
local dialogueLayout = Instance.new("UIListLayout", dialogueFrame)
dialogueLayout.Padding = UDim.new(0, 8)

local function showDialogue(options)
	for _, child in dialogueFrame:GetChildren() do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, response in options do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, 0, 0, 70)
		button.Text = response
		button.TextWrapped = true
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 14
		button.BackgroundColor3 = Color3.fromRGB(42, 49, 68)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Parent = dialogueFrame
		button.Activated:Connect(function()
			Remotes.MonsterDialogueChoice:FireServer(response)
			dialogueFrame.Visible = false
		end)
	end
	dialogueFrame.Visible = true
end

Remotes.RoleAssigned.OnClientEvent:Connect(function(role)
	guessFrame.Visible = role == "Detective"
end)

task.spawn(function()
	local role = Remotes.GetMyRole:InvokeServer()
	guessFrame.Visible = role == "Detective"
end)

Remotes.VictimStateChanged.OnClientEvent:Connect(function(state)
	label.Visible = true
	local tasks = { "Make a lockpick", "Solve the door puzzle", "Solve the room puzzle", "Pick the final lock", "Reach the police station" }
	local taskText = state.EscapedHouse and tasks[5] or tasks[math.clamp(state.Stage, 1, 4)]
	label.Text = string.format("Hunger %d%%  |  Thirst %d%%  |  Food %d  |  Water %d\nTask: %s (%d%%)",
		state.Hunger, state.Thirst, state.FoodSupplies, state.WaterSupplies, taskText, state.Progress * 100)
end)

Remotes.MonsterTaskChanged.OnClientEvent:Connect(function(state)
	label.Visible = true
	label.Text = string.format("Day cover activities: %d/2\nNight citizens eaten: %d/1",
		state.DayActivityCount, state.NightKills)
	if state.ResponseOptions then showDialogue(state.ResponseOptions) end
end)

local function pointInside(part, point)
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half = part.Size * 0.5
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Z) <= half.Z
end

RunService:BindToRenderStep("PreventBasementView", Enum.RenderPriority.Camera.Value + 1, function()
	if player:GetAttribute("RoundRole") ~= "Detective" then return end
	local camera = workspace.CurrentCamera
	if not camera or camera.CFrame.LookVector.Y >= -0.15 then return end
	for _, zone in CollectionService:GetTagged("BasementZone") do
		if zone:IsA("BasePart") and pointInside(zone, camera.CFrame.Position) then
			local look = camera.CFrame.LookVector
			local flattened = Vector3.new(look.X, -0.15, look.Z).Unit
			camera.CFrame = CFrame.lookAt(camera.CFrame.Position, camera.CFrame.Position + flattened)
			break
		end
	end
end)
