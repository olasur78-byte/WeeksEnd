local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage.Modules.GameConfig)
local NPCProfiles = require(ReplicatedStorage.Modules.NPCProfiles)
local RoundState = require(script.Parent.RoundState)
local states = {}
local lastInteraction = {}

local function stateFor(player)
	local state = states[player]
	if not state then
		state = { Activities = {}, DayActivityCount = 0, NightKills = 0, NightComplete = false, RoundId = RoundState.GetSnapshot().Id }
		states[player] = state
	end
	return state
end

local function publish(player)
	Remotes.MonsterTaskChanged:FireClient(player, table.clone(stateFor(player)))
end

local function civilianFrom(instance)
	local model = instance and instance:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("IsCivilian") then return model end
	return nil
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if RoundState.GetRole(player) ~= "Kidnapper" or not RoundState.IsActive() then return end
	local now = os.clock()
	if now - (lastInteraction[player] or 0) < Config.Monster.InteractionCooldown then return end
	lastInteraction[player] = now

	local state = stateFor(player)
	local civilian = civilianFrom(prompt.Parent)
	if civilian then
		if RoundState.IsDay() then
			if not state.Activities.CivilianConversation then
				state.Activities.CivilianConversation = true
				state.DayActivityCount += 1
			end
		else
			if state.NightKills >= Config.Monster.NightKillsRequired then return end
			state.NightKills += 1
			state.NightComplete = state.NightKills == Config.Monster.NightKillsRequired
			civilian:SetAttribute("ConsumedByMonster", player.UserId)
			local humanoid = civilian:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid.Health = 0 else civilian:Destroy() end
		end
		publish(player)
		return
	end

	if not RoundState.IsDay() then return end
	local activity = prompt:GetAttribute("MonsterActivity") or prompt.Parent:GetAttribute("MonsterActivity")
	if not activity then
		local path = prompt:GetFullName():lower()
		if path:find("pharmacy", 1, true) then activity = "Pharmacy"
		elseif path:find("store", 1, true) or path:find("grocery", 1, true) then activity = "Groceries"
		elseif path:find("police", 1, true) or path:find("question", 1, true) then activity = "PoliceQuestioning" end
	end
	if activity and not state.Activities[activity] then
		if activity == "PoliceQuestioning" then
			state.ResponseOptions = {
				NPCProfiles.WitnessResponses[1], NPCProfiles.WitnessResponses[2], NPCProfiles.WitnessResponses[3],
			}
			publish(player)
			return
		end
		state.Activities[activity] = true
		state.DayActivityCount += 1
		publish(player)
	end
end)

Remotes.MonsterDialogueChoice.OnServerEvent:Connect(function(player, response)
	if RoundState.GetRole(player) ~= "Kidnapper" or type(response) ~= "string" then return end
	local state = stateFor(player)
	if not state.ResponseOptions or not table.find(state.ResponseOptions, response) then return end
	state.ResponseOptions = nil
	if not state.Activities.PoliceQuestioning then
		state.Activities.PoliceQuestioning = true
		state.DayActivityCount += 1
	end
	publish(player)
end)

task.spawn(function()
	local previousRound = 0
	local previousTime = "Day"
	while true do
		task.wait(1)
		local snapshot = RoundState.GetSnapshot()
		if snapshot.Id ~= previousRound then
			previousRound = snapshot.Id
			previousTime = snapshot.TimeOfDay
			table.clear(states)
		elseif snapshot.TimeOfDay ~= previousTime then
			previousTime = snapshot.TimeOfDay
			if previousTime == "Night" and snapshot.Kidnapper then
				local state = stateFor(snapshot.Kidnapper)
				state.NightKills = 0
				state.NightComplete = false
				publish(snapshot.Kidnapper)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
	lastInteraction[player] = nil
end)
