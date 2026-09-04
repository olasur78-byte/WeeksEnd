local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoleConfig = require(Modules.RoleConfig)
local RoleService = require(script.Parent.RoleService)
local RoundState = require(script.Parent.RoundState)

local function rootOf(instance)
	if instance:IsA("BasePart") then return instance end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function taggedOrNamed(tag, names)
	local found = CollectionService:GetTagged(tag)
	if #found > 0 then return found end
	local results = {}
	for _, descendant in workspace:GetDescendants() do
		local lowerName = descendant.Name:lower()
		local nameMatch = table.find(names, descendant.Name) or (tag == "KidnapHouse" and lowerName:find("house", 1, true))
		if nameMatch and (descendant:IsA("Model") or descendant:IsA("BasePart")) then
			table.insert(results, descendant)
		end
	end
	return results
end

local function teleport(player, target)
	local character = player.Character or player.CharacterAdded:Wait()
	local targetPart = target and rootOf(target)
	if character and targetPart then character:PivotTo(targetPart.CFrame + Vector3.new(0, 3, 0)) end
end

local function chooseHouse()
	local houses = taggedOrNamed("KidnapHouse", { "House", "House1", "House2", "House3", "House4", "House5", "House6" })
	return #houses > 0 and houses[math.random(1, #houses)] or nil
end

local function houseSpawn(house)
	if not house then return nil end
	return house:FindFirstChild("KidnapSpawn", true)
		or house:FindFirstChild("BasementSpawn", true)
		or house:FindFirstChild("BF", true)
		or rootOf(house)
end

local function publicSpawn()
	local spawns = taggedOrNamed("RoundSpawn", { "PoliceSpawn", "DetectiveSpawn", "SpawnLocation" })
	return spawns[1]
end

local function startRound()
	local assignment = RoleService.Assign(RoundState)
	if not assignment then return false end
	local house = chooseHouse()
	RoundState.Begin(assignment, house)

	for _, player in assignment.Players do
		Remotes.RoleAssigned:FireClient(player, RoundState.GetRole(player), RoundState.GetMonster(player))
	end

	local captiveSpawn = houseSpawn(house)
	teleport(assignment.Kidnapper, captiveSpawn)
	teleport(assignment.Victim, captiveSpawn)
	for _, player in assignment.Players do
		if player ~= assignment.Kidnapper and player ~= assignment.Victim then teleport(player, publicSpawn()) end
	end

	Remotes.RoundStateChanged:FireAllClients("RoundStarted", RoundState.GetSnapshot())
	task.spawn(function()
		local elapsed = 0
		while RoundState.IsActive() and elapsed < RoleConfig.RoundDuration do
			local duration = RoundState.IsDay() and RoleConfig.DayDuration or RoleConfig.NightDuration
			task.wait(duration)
			elapsed += duration
			if RoundState.IsActive() then
				RoundState.SetTimeOfDay(RoundState.IsDay() and "Night" or "Day")
				Remotes.RoundStateChanged:FireAllClients("TimeOfDayChanged", RoundState.GetSnapshot())
			end
		end
		if RoundState.IsActive() then
			RoundState.End("Monster")
			Remotes.RoundStateChanged:FireAllClients("RoundEnded", RoundState.GetSnapshot())
		end
	end)
	return true
end

Remotes.GetMyRole.OnServerInvoke = function(player)
	return RoundState.GetRole(player), RoundState.GetMonster(player)
end
Remotes.GetRoundSnapshot.OnServerInvoke = function() return RoundState.GetSnapshot() end
Players.PlayerRemoving:Connect(function(player) RoundState.PlayerRemoving(player) end)

task.spawn(function()
	while true do
		while #Players:GetPlayers() < RoleConfig.MinPlayers do task.wait(1) end
		Remotes.RoundStateChanged:FireAllClients("Intermission", { Duration = RoleConfig.IntermissionDuration })
		task.wait(RoleConfig.IntermissionDuration)
		if startRound() then
			while RoundState.IsActive() do task.wait(1) end
			task.wait(RoleConfig.RoundStartDelay)
		end
	end
end)
