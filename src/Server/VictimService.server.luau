local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage.Modules.GameConfig)
local RoundState = require(script.Parent.RoundState)
local states = {}

local sequence = { "LockpickCraft", "DoorPuzzle", "RoomPuzzle", "FinalDoor" }

local function publish(player)
	local state = states[player]
	if state then Remotes.VictimStateChanged:FireClient(player, table.clone(state)) end
end

local function reset(player)
	local roundId = RoundState.GetSnapshot().Id
	player:SetAttribute("VictimEscapedHouse", false)
	states[player] = {
		Hunger = math.random(Config.Needs.MinimumSupply, Config.Needs.MaximumSupply),
		Thirst = math.random(Config.Needs.MinimumSupply, Config.Needs.MaximumSupply),
		FoodSupplies = math.random(1, 3), WaterSupplies = math.random(1, 3),
		Stage = 1, Progress = 0, EscapedHouse = false, Completed = {}, ActiveToken = 0, RoundId = roundId,
	}
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Once(function()
			if RoundState.IsActive() and RoundState.GetRole(player) == "Kidnapped" then
				RoundState.End("Monster")
				Remotes.RoundStateChanged:FireAllClients("RoundEnded", RoundState.GetSnapshot())
			end
		end)
	end
	publish(player)
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if RoundState.GetRole(player) ~= "Kidnapped" then return end
	local state = states[player]
	if not state then return end
	local supplyType = prompt:GetAttribute("SupplyType") or prompt.Parent:GetAttribute("SupplyType")
	if supplyType == "Food" and state.FoodSupplies > 0 then
		state.FoodSupplies -= 1
		state.Hunger = math.min(100, state.Hunger + 30)
		publish(player)
		return
	elseif supplyType == "Water" and state.WaterSupplies > 0 then
		state.WaterSupplies -= 1
		state.Thirst = math.min(100, state.Thirst + 40)
		publish(player)
		return
	end
	local taskId = prompt:GetAttribute("VictimTask") or prompt.Parent:GetAttribute("VictimTask")
	if prompt:GetAttribute("VictimTaskSequence") or prompt.Parent:GetAttribute("VictimTaskSequence") then
		local sequenceEnd = prompt:GetAttribute("VictimTaskSequenceEnd") or prompt.Parent:GetAttribute("VictimTaskSequenceEnd") or #sequence
		if state.Stage > sequenceEnd then return end
		taskId = sequence[state.Stage]
	end
	if not state or taskId ~= sequence[state.Stage] then return end
	local definition = Config.VictimTasks[taskId]
	if not definition then return end

	state.ActiveToken += 1
	local token = state.ActiveToken
	state.Progress = 0
	for second = 1, definition.Duration do
		task.wait(1)
		if token ~= state.ActiveToken or not RoundState.IsActive() then return end
		local kidnapper = RoundState.GetSnapshot().Kidnapper
		local victimRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local monsterRoot = kidnapper and kidnapper.Character and kidnapper.Character:FindFirstChild("HumanoidRootPart")
		if definition.Resettable and victimRoot and monsterRoot and (victimRoot.Position - monsterRoot.Position).Magnitude < 30 then
			state.Progress = 0
			state.ActiveToken += 1
			publish(player)
			return
		end
		state.Progress = second / definition.Duration
		publish(player)
	end
	state.Completed[taskId] = true
	state.Stage += 1
	state.Progress = 0
	if taskId == "FinalDoor" then
		state.EscapedHouse = true
		player:SetAttribute("VictimEscapedHouse", true)
	end
	publish(player)
end)

task.spawn(function()
	while true do
		task.wait(10)
		for player, state in pairs(states) do
			if RoundState.GetRole(player) == "Kidnapped" and RoundState.IsActive() then
				state.Hunger = math.max(0, state.Hunger - Config.Needs.HungerLossPerMinute / 6)
				state.Thirst = math.max(0, state.Thirst - Config.Needs.ThirstLossPerMinute / 6)
				if state.Hunger == 0 or state.Thirst == 0 then
					local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
					if humanoid then humanoid:TakeDamage(Config.Needs.DamageAtZero) end
				end
				publish(player)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player) states[player] = nil end)

task.spawn(function()
	while true do
		task.wait(1)
		local victim = RoundState.GetSnapshot().Victim
		local snapshot = RoundState.GetSnapshot()
		if victim and RoundState.GetRole(victim) == "Kidnapped"
			and (not states[victim] or states[victim].RoundId ~= snapshot.Id) then
			reset(victim)
		end
	end
end)
