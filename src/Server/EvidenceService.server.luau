local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local EvidenceDefinitions = require(ReplicatedStorage.Modules.EvidenceDefinitions)
local RoundState = require(script.Parent.RoundState)
local collected = {}

local function send(player, evidence)
	local byPlayer = collected[player] or {}
	collected[player] = byPlayer
	local roundEvidenceId = tostring(RoundState.GetSnapshot().Id) .. "_" .. evidence.Id
	if byPlayer[roundEvidenceId] then return end
	byPlayer[roundEvidenceId] = true
	Remotes.CaseFileUpdated:FireClient(player, {
		Type = "Evidence", Id = roundEvidenceId, Title = evidence.Title,
		Description = evidence.Description, Reliability = evidence.Reliability,
		Suspects = evidence.Suspects,
	})
end

local function near(player, instance, maximum)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local part = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart")
	return root and part and (root.Position - part.Position).Magnitude <= maximum + 3
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	if RoundState.GetRole(player) ~= "Detective" or not near(player, prompt.Parent, prompt.MaxActivationDistance) then return end
	local kind = prompt:GetAttribute("EvidenceKind") or prompt.Parent:GetAttribute("EvidenceKind")
	if not kind then
		local model = prompt:FindFirstAncestorOfClass("Model")
		if model and model:GetAttribute("IsCivilian") then kind = "Witness" end
	end
	if kind == "Visual" and not RoundState.IsDay() then
		Remotes.CaseFileUpdated:FireClient(player, { Type = "Info", Title = "Camera offline", Description = "CCTV is disabled at night." })
		return
	end
	if kind == "Witness" then
		local model = prompt:FindFirstAncestorOfClass("Model")
		local evidence = EvidenceDefinitions.ForMonster(RoundState.GetMonster(RoundState.GetSnapshot().Kidnapper), "Witness")
		if evidence and model then
			local statement = model:GetAttribute("WitnessStatement")
			if statement then evidence.Description = statement .. " " .. evidence.Description end
		end
		if evidence then send(player, evidence) end
	elseif kind then
		local evidence = EvidenceDefinitions.ForMonster(RoundState.GetMonster(RoundState.GetSnapshot().Kidnapper), kind)
		if evidence then send(player, evidence) end
	end
end)

Remotes.SubmitMonsterGuess.OnServerInvoke = function(player, monsterId)
	if RoundState.GetRole(player) ~= "Detective" or type(monsterId) ~= "string" then return false, "Not allowed" end
	if not RoundState.GetSnapshot().VictimRescued then return false, "The victim must also reach the police station." end
	local actual = RoundState.GetMonster(RoundState.GetSnapshot().Kidnapper)
	if monsterId ~= actual then return false, "Incorrect monster type." end
	RoundState.MarkMonsterIdentified()
	RoundState.End("Police")
	Remotes.RoundStateChanged:FireAllClients("RoundEnded", RoundState.GetSnapshot())
	return true, "Victim rescued and monster identified."
end

Players.PlayerRemoving:Connect(function(player) collected[player] = nil end)
