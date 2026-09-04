local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.GameConfig)
local RoundState = require(script.Parent.RoundState)
local safePositions = {}
local safeNPCPositions = {}

local function inside(zone, position)
	if zone:IsA("BasePart") then
		local localPosition = zone.CFrame:PointToObjectSpace(position)
		local half = zone.Size * 0.5
		return math.abs(localPosition.X) <= half.X and math.abs(localPosition.Y) <= half.Y and math.abs(localPosition.Z) <= half.Z
	end
	local parts = {}
	for _, item in zone:GetDescendants() do if item:IsA("BasePart") then table.insert(parts, item) end end
	if #parts == 0 then return false end
	local minimum, maximum
	for _, part in parts do
		local half = part.Size * 0.5
		local low, high = part.Position - half, part.Position + half
		minimum = minimum and Vector3.new(math.min(minimum.X, low.X), math.min(minimum.Y, low.Y), math.min(minimum.Z, low.Z)) or low
		maximum = maximum and Vector3.new(math.max(maximum.X, high.X), math.max(maximum.Y, high.Y), math.max(maximum.Z, high.Z)) or high
	end
	if zone:HasTag(Config.Zones.BasementTag) then
		local floor = zone:FindFirstChild("BF", true)
		local ceilingY = floor and floor.Position.Y + 12 or minimum.Y + (maximum.Y - minimum.Y) * 0.45
		maximum = Vector3.new(maximum.X, ceilingY, maximum.Z)
	end
	return position.X >= minimum.X and position.X <= maximum.X
		and position.Y >= minimum.Y and position.Y <= maximum.Y
		and position.Z >= minimum.Z and position.Z <= maximum.Z
end

local function zones(tag, fallbackName)
	local tagged = CollectionService:GetTagged(tag)
	if #tagged > 0 then return tagged end
	local result = {}
	for _, item in workspace:GetDescendants() do
		if item:IsA("BasePart") and item.Name == fallbackName then table.insert(result, item) end
	end
	return result
end

local function inAny(parts, position)
	for _, part in parts do if inside(part, position) then return true end end
	return false
end

local function protectDetective(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	local previous = humanoid.Health
	humanoid.HealthChanged:Connect(function(health)
		if RoundState.GetRole(player) == "Detective" and health < previous then humanoid.Health = previous else previous = health end
	end)
end

local function watchPlayer(player)
	player.CharacterAdded:Connect(function(character) protectDetective(player, character) end)
	if player.Character then protectDetective(player, player.Character) end
end

for _, player in Players:GetPlayers() do watchPlayer(player) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(player) safePositions[player] = nil end)

task.spawn(function()
	while true do
		task.wait(0.2)
		local basements = zones(Config.Zones.BasementTag, "BasementZone")
		local station = zones(Config.Zones.PoliceStationTag, "PoliceStationZone")
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local role = RoundState.GetRole(player)
				local forbidden = (role == "Detective" and inAny(basements, root.Position))
					or (role == "Kidnapper" and inAny(station, root.Position))
				if forbidden and safePositions[player] then
					player.Character:PivotTo(safePositions[player])
				elseif not forbidden then
					safePositions[player] = root.CFrame
				end
				local victimState = player:GetAttribute("VictimEscapedHouse")
				if role == "Kidnapped" and victimState and inAny(station, root.Position)
					and not RoundState.GetSnapshot().VictimRescued then
					RoundState.MarkVictimRescued()
					ReplicatedStorage.Remotes.RoundStateChanged:FireAllClients("VictimRescued", RoundState.GetSnapshot())
				end
			end
		end
		local npcFolder = workspace:FindFirstChild("NPCs")
		if npcFolder then
			for _, npc in npcFolder:GetChildren() do
				if npc:IsA("Model") and npc:GetAttribute("IsCivilian") then
					local root = npc:FindFirstChild("HumanoidRootPart")
					if root then
						if inAny(station, root.Position) then
							if safeNPCPositions[npc] then npc:PivotTo(safeNPCPositions[npc]) end
						else
							safeNPCPositions[npc] = root.CFrame
						end
					end
				end
			end
		end
	end
end)
