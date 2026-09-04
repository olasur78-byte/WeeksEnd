local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local NPCProfiles = require(game.ReplicatedStorage.Modules.NPCProfiles)

local NPC_COUNT = 25
local WALK_ANIMATION_ID = "rbxassetid://507777826"
local PATH_PARAMETERS = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	WaypointSpacing = 5,
}

-- Create NPC folder
local npcFolder = workspace:FindFirstChild("NPCs")
if not npcFolder then
	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = workspace
end

-- A set makes removal constant-time and is also used to keep spawn positions apart.
local activeNPCs = {}

local function getStreetParts()
	local points = {}
	for _, tagged in CollectionService:GetTagged("NPCStreet") do
		if tagged:IsA("BasePart") then table.insert(points, tagged) end
	end
	if #points == 0 then
		for _, part in workspace:GetDescendants() do
			if part:IsA("BasePart") and part.Anchored and part.CanCollide then
				local name = part.Name:lower()
				local streetName = name:find("road", 1, true) or name:find("street", 1, true)
					or name:find("sidewalk", 1, true) or name:find("pavement", 1, true)
					or name:find("asphalt", 1, true)
				if streetName and part.CFrame.UpVector.Y > 0.75 and math.min(part.Size.X, part.Size.Z) >= 4 then
					table.insert(points, part)
				end
			end
		end
	end
	return points
end

local function getNavigationPoints()
	local points = getStreetParts()
	for _, tagged in CollectionService:GetTagged("NPCWaypoint") do
		if tagged:IsA("BasePart") then table.insert(points, tagged) end
	end
	return points
end

local function getPointsOfInterest()
	local results = {}
	local seen = {}
	for _, tagged in CollectionService:GetTagged("NPCPointOfInterest") do
		local part = if tagged:IsA("BasePart") then tagged else tagged:FindFirstChildWhichIsA("BasePart", true)
		if part and not seen[part] then seen[part], results[#results + 1] = true, part end
	end
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			local activity = descendant:GetAttribute("MonsterActivity")
				or (descendant.Parent and descendant.Parent:GetAttribute("MonsterActivity"))
			local part = descendant.Parent
			if activity and part and part:IsA("BasePart") and not seen[part] then
				seen[part], results[#results + 1] = true, part
			end
		end
	end
	return results
end

local function getRandomDestination(exclude, origin)
	local points = getNavigationPoints()
	if #points == 0 then return nil end
	local bestSurface = nil
	local bestPosition = nil
	local bestDistance = -1
	-- Sample several places and prefer the furthest reachable-looking target.
	-- This makes civilians traverse the settlement instead of orbiting one block.
	for _ = 1, math.min(16, math.max(6, #points * 2)) do
		local surface = points[math.random(1, #points)]
		if surface ~= exclude or #points <= 1 then
			local halfX = math.max(0, surface.Size.X * 0.42)
			local halfZ = math.max(0, surface.Size.Z * 0.42)
			local offset = Vector3.new((math.random() * 2 - 1) * halfX, surface.Size.Y * 0.5 + 2.5, (math.random() * 2 - 1) * halfZ)
			local candidate = surface.CFrame:PointToWorldSpace(offset)
			local distance = (candidate - origin).Magnitude
			if distance > bestDistance then
				bestSurface, bestPosition, bestDistance = surface, candidate, distance
			end
		end
	end
	return bestSurface, bestPosition
end

local function isAwayFromReservedSpawns(candidate)
	for _, tagged in CollectionService:GetTagged("RoundSpawn") do
		if tagged:IsA("BasePart") and (tagged.Position - candidate).Magnitude < 35 then return false end
	end
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") and (descendant.Position - candidate).Magnitude < 35 then return false end
	end
	return true
end

local function spawnPositionFor(part)
	for _ = 1, 50 do
		local halfX = math.max(0, part.Size.X * 0.42)
		local halfZ = math.max(0, part.Size.Z * 0.42)
		local offset = Vector3.new((math.random() * 2 - 1) * halfX, part.Size.Y * 0.5 + 3, (math.random() * 2 - 1) * halfZ)
		local candidate = part.CFrame:PointToWorldSpace(offset)
		local farEnough = isAwayFromReservedSpawns(candidate)
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - candidate).Magnitude < 30 then
				farEnough = false
				break
			end
		end
		if farEnough then
			for npc in activeNPCs do
				local root = npc:FindFirstChild("HumanoidRootPart")
				if root and (root.Position - candidate).Magnitude < 10 then
					farEnough = false
					break
				end
			end
		end
		if farEnough then return candidate end
	end
	return nil
end

local function applyRandomAppearance(model)
	local bodyColors = model:FindFirstChild("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = model
	end

	local skin = NPCProfiles.randomFrom(NPCProfiles.SkinTones)
	bodyColors.HeadColor3 = skin
	bodyColors.LeftArmColor3 = skin
	bodyColors.RightArmColor3 = skin
	bodyColors.TorsoColor3 = NPCProfiles.randomFrom(NPCProfiles.ShirtColors)
	local pantsColor = NPCProfiles.randomFrom(NPCProfiles.PantsColors)
	bodyColors.LeftLegColor3 = pantsColor
	bodyColors.RightLegColor3 = pantsColor
end

local function nearestCivilian(model, radius)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local nearest, nearestDistance = nil, radius
	for other in activeNPCs do
		if other ~= model then
			local otherRoot = other:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				local distance = (otherRoot.Position - root.Position).Magnitude
				if distance < nearestDistance then
					nearest, nearestDistance = otherRoot, distance
				end
			end
		end
	end
	return nearest
end

local function changeSpeedSmoothly(humanoid, speed)
	TweenService:Create(humanoid, TweenInfo.new(0.65, Enum.EasingStyle.Sine), { WalkSpeed = speed }):Play()
end

local function spawnNPC(spawnPosition)
	local hd, presentation = NPCProfiles.createCivilianProfile()

	local success, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R15)
	end)

	if not success or not model then
		warn("NPCService: Failed to create NPC model")
		return nil
	end

	model.Name = "Civilian_" .. math.random(1000, 9999)
	model:SetAttribute("IsCivilian", true)
	model:SetAttribute("Presentation", presentation)
	model:SetAttribute("WitnessStatement", NPCProfiles.randomFrom(NPCProfiles.WitnessResponses))
	model:PivotTo(CFrame.new(spawnPosition))
	applyRandomAppearance(model)
	model.Parent = npcFolder
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant:SetNetworkOwner(nil)
		end
	end
	local interactionPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
	if interactionPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CivilianInteraction"
		prompt.ActionText = "Interact"
		prompt.ObjectText = ""
		prompt.HoldDuration = 1
		prompt.MaxActivationDistance = 10
		prompt.Parent = interactionPart
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		warn("NPCService: NPC has no humanoid")
		model.Parent = nil
		return nil
	end

	humanoid.WalkSpeed = 8 + math.random(0, 4)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.DisplayName = ""

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local walkAnimation = Instance.new("Animation")
	walkAnimation.AnimationId = WALK_ANIMATION_ID
	local walkTrack = animator:LoadAnimation(walkAnimation)
	walkTrack.Looped = true
	walkTrack.Priority = Enum.AnimationPriority.Movement
	humanoid.Running:Connect(function(speed)
		if speed > 0.5 then
			if not walkTrack.IsPlaying then walkTrack:Play(0.2) end
			walkTrack:AdjustSpeed(math.clamp(speed / 10, 0.6, 1.4))
		elseif walkTrack.IsPlaying then
			walkTrack:Stop(0.2)
		end
	end)

	activeNPCs[model] = true

	-- Civilians alternate between idling, roaming and visiting useful places.
	local currentSurface = nil
	local normalWalkSpeed = 7 + math.random() * 3

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			local decision = math.random()
			if decision < 0.2 then
				humanoid:Move(Vector3.zero)
				changeSpeedSmoothly(humanoid, 0)
				task.wait(math.random(3, 10))
				changeSpeedSmoothly(humanoid, normalWalkSpeed)
				continue
			end

			local targetPosition
			local visiting = false
			if decision < 0.5 then
				local places = getPointsOfInterest()
				if #places > 0 then
					local place = places[math.random(1, #places)]
					targetPosition = place.Position + place.CFrame.LookVector * 4
					visiting = true
				end
			end
			if not targetPosition then
				currentSurface, targetPosition = getRandomDestination(currentSurface, model:GetPivot().Position)
			end
			if not targetPosition then
				task.wait(5)
				continue
			end

			local running = math.random() < 0.14
			changeSpeedSmoothly(humanoid, if running then math.random(15, 18) else normalWalkSpeed)

			local path = PathfindingService:CreatePath(PATH_PARAMETERS)

			local pathSuccess = pcall(function()
				path:ComputeAsync(model:GetPivot().Position, targetPosition)
			end)

			if pathSuccess and path.Status == Enum.PathStatus.Success then
				local waypoints = path:GetWaypoints()
				local blocked = false
				local waypointIndex = 2
				local blockedConnection = path.Blocked:Connect(function(blockedIndex)
					if blockedIndex >= waypointIndex then blocked = true end
				end)
				for i = 2, #waypoints do
					if humanoid.Health <= 0 or not model.Parent then return end
					if blocked then break end
					waypointIndex = i

					local nearbyRoot = nearestCivilian(model, 4.5)
					if nearbyRoot then
						-- Briefly yield and step sideways instead of forming a pile.
						changeSpeedSmoothly(humanoid, normalWalkSpeed * 0.55)
						local root = model:FindFirstChild("HumanoidRootPart")
						if root then
							humanoid:MoveTo(root.Position + root.CFrame.RightVector * (math.random(0, 1) == 0 and -3 or 3))
							task.wait(math.random(4, 10) / 10)
						end
						changeSpeedSmoothly(humanoid, if running then 16 else normalWalkSpeed)
					end

					local wp = waypoints[i]
					if wp.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end

					humanoid:MoveTo(wp.Position)
					local reached = humanoid.MoveToFinished:Wait()
					if not reached then break end
				end
				blockedConnection:Disconnect()
			else
				-- Never walk directly through geometry. Wait and choose another
				-- mapped point when pathfinding cannot reach this destination.
				task.wait(1)
			end

			if humanoid.Health <= 0 or not model.Parent then return end
			changeSpeedSmoothly(humanoid, 0)
			task.wait(if visiting then math.random(5, 14) else math.random(2, 7))
			changeSpeedSmoothly(humanoid, normalWalkSpeed)
		end
	end)

	-- Handle death/respawn
	humanoid.Died:Connect(function()
		task.wait(5)
		if model.Parent then
			model.Parent = nil
		end

		activeNPCs[model] = nil

		local streets = getStreetParts()
		if #streets > 0 then
			local pos = spawnPositionFor(streets[math.random(1, #streets)])
			if pos then
				task.wait(1)
				spawnNPC(pos)
			end
		end
	end)

	return model
end

-- Initialize NPCs
local function initializeNPCs()
	local streetParts = getStreetParts()
	if #streetParts == 0 then
		warn("NPCService: No street surfaces found. Tag road/sidewalk parts with NPCStreet.")
		return
	end

	for i = 1, NPC_COUNT do
		local spawnPart = streetParts[math.random(1, #streetParts)]
		local pos = spawnPositionFor(spawnPart)
		if pos then spawnNPC(pos) end
		task.wait(0.3)
	end

	print("NPCService: Spawned " .. NPC_COUNT .. " NPCs")
end

initializeNPCs()
