local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local NPCProfiles = require(game.ReplicatedStorage.Modules.NPCProfiles)

local NPC_COUNT = 25
local WALK_ANIMATION_ID = "rbxassetid://507777826"
local PATH_PARAMETERS = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
}

-- Create NPC folder
local npcFolder = workspace:FindFirstChild("NPCs")
if not npcFolder then
	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = workspace
end

-- Waypoints: key locations NPCs walk between
local WAYPOINTS = {
	Vector3.new(0, 3, 5),
	Vector3.new(29, 3, 50),
	Vector3.new(-35, 3, 55),
	Vector3.new(-75, 3, -55),
	Vector3.new(-35, 3, -55),
	Vector3.new(5, 3, -45),
	Vector3.new(45, 3, -55),
	Vector3.new(75, 3, -55),
	Vector3.new(-15, 3, 20),
	Vector3.new(15, 3, 20),
	Vector3.new(0, 3, -25),
	Vector3.new(-20, 3, 5),
	Vector3.new(20, 3, 5),
	Vector3.new(-50, 3, 0),
	Vector3.new(50, 3, 0),
	Vector3.new(20, 3, 22),   -- Cafe entrance
	Vector3.new(-20, 3, 22),  -- Pharmacy entrance
	Vector3.new(0, 3, 35),    -- Park fountain
	Vector3.new(0, 3, 42),     -- Park south
	Vector3.new(-12, 3, 30),  -- Park west
	Vector3.new(12, 3, 30),    -- Park east
}

local function getRandomWaypoint(exclude)
	local wp
	repeat
		wp = WAYPOINTS[math.random(1, #WAYPOINTS)]
	until wp ~= exclude or #WAYPOINTS <= 1
	return wp
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

-- A set makes removal constant-time and avoids scanning the whole NPC list on death.
local activeNPCs = {}

local function spawnNPC(spawnPosition, npcName)
	local hd = NPCProfiles.createRandomDescription()

	local success, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(hd, Enum.HumanoidRigType.R15)
	end)

	if not success or not model then
		warn("NPCService: Failed to create NPC model")
		return nil
	end

	model.Name = npcName or ("NPC_" .. math.random(1000, 9999))
	model:SetAttribute("IsCivilian", true)
	model:SetAttribute("WitnessStatement", NPCProfiles.randomFrom(NPCProfiles.WitnessResponses))
	model:PivotTo(CFrame.new(spawnPosition))
	applyRandomAppearance(model)
	model.Parent = npcFolder
	local interactionPart = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
	if interactionPart then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CivilianInteraction"
		prompt.ActionText = "Interact"
		prompt.ObjectText = model.Name
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
	humanoid.DisplayName = model.Name

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

	-- Start walking behavior
	local currentTarget = nil

	task.spawn(function()
		while model.Parent and humanoid.Health > 0 do
			currentTarget = getRandomWaypoint(currentTarget)

			local path = PathfindingService:CreatePath(PATH_PARAMETERS)

			local pathSuccess = pcall(function()
				path:ComputeAsync(model:GetPivot().Position, currentTarget)
			end)

			if pathSuccess and path.Status == Enum.PathStatus.Success then
				local waypoints = path:GetWaypoints()
				for i = 2, #waypoints do
					if humanoid.Health <= 0 or not model.Parent then return end

					local wp = waypoints[i]
					if wp.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end

					humanoid:MoveTo(wp.Position)
					local reached = humanoid.MoveToFinished:Wait()
					if not reached then break end
				end
			else
				-- Fallback: direct move
				humanoid:MoveTo(currentTarget)
				humanoid.MoveToFinished:Wait()
			end

			if humanoid.Health <= 0 or not model.Parent then return end
			task.wait(math.random(2, 8))
		end
	end)

	-- Handle death/respawn
	humanoid.Died:Connect(function()
		task.wait(5)
		if model.Parent then
			model.Parent = nil
		end

		activeNPCs[model] = nil

		local spawns = workspace:FindFirstChild("NPCSpawns")
		if spawns then
			local spawnParts = spawns:GetChildren()
			if #spawnParts > 0 then
				local spawnPart = spawnParts[math.random(1, #spawnParts)]
				local name = NPCProfiles.randomFrom(NPCProfiles.Names)
				local pos = spawnPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
				task.wait(1)
				spawnNPC(pos, name)
			end
		end
	end)

	return model
end

-- Initialize NPCs
local function initializeNPCs()
	local spawns = workspace:FindFirstChild("NPCSpawns")
	if not spawns then
		warn("NPCService: No NPCSpawns folder found!")
		return
	end

	local spawnParts = spawns:GetChildren()
	if #spawnParts == 0 then
		warn("NPCService: No spawn points found!")
		return
	end

	for i = 1, NPC_COUNT do
		local spawnPart = spawnParts[math.random(1, #spawnParts)]
		local name = NPCProfiles.randomFrom(NPCProfiles.Names)
		local pos = spawnPart.Position + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
		spawnNPC(pos, name)
		task.wait(0.3)
	end

	print("NPCService: Spawned " .. NPC_COUNT .. " NPCs")
end

initializeNPCs()
