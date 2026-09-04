local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local EvidenceDefinitions = require(Modules:WaitForChild("EvidenceDefinitions"))
local RoundState = require(script.Parent:WaitForChild("RoundState"))

local caseFileUpdatedRemote = Remotes:WaitForChild("CaseFileUpdated")

-- Keeps each detective from collecting the exact same evidence repeatedly.
local collectedEvidence = {}

local function isNearCamera(player, cameraBody, prompt)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return false
	end

	local distance = (rootPart.Position - cameraBody.Position).Magnitude
	return distance <= prompt.MaxActivationDistance + 3
end

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local cameraBody = prompt.Parent

	if not cameraBody or not cameraBody:IsA("BasePart") then
		return
	end

	if cameraBody:GetAttribute("EvidenceType") ~= "CCTV" then
		return
	end

	-- Only detectives may investigate cameras.
	if RoundState.GetRole(player) ~= "Detective" then
		return
	end
	if not RoundState.IsDay() then
		caseFileUpdatedRemote:FireClient(player, {
			Type = "Info", Title = "Camera offline",
			Description = "CCTV is disabled during the night.",
		})
		return
	end

	-- Extra server check for distance.
	if not isNearCamera(player, cameraBody, prompt) then
		return
	end

	local cameraId = cameraBody:GetAttribute("CameraId")
	local snapshot = RoundState.GetSnapshot()
	local clue = EvidenceDefinitions.ForMonster(RoundState.GetMonster(snapshot.Kidnapper), "Visual")
		or EvidenceDefinitions.CCTV[cameraId]

	if not clue then
		warn("No CCTV clue exists for CameraId: " .. tostring(cameraId))
		return
	end

	collectedEvidence[player.UserId] = collectedEvidence[player.UserId] or {}

	local evidenceId = tostring(RoundState.GetSnapshot().Id) .. "_" .. clue.Id
	if collectedEvidence[player.UserId][evidenceId] then
		caseFileUpdatedRemote:FireClient(player, {
			Type = "AlreadyCollected",
			Title = "Case File",
			Description = "You already reviewed this footage.",
		})
		return
	end

	collectedEvidence[player.UserId][evidenceId] = true

	caseFileUpdatedRemote:FireClient(player, {
		Type = "Evidence",
		Id = evidenceId,
		Title = clue.Title,
		Description = clue.Description,
		Reliability = clue.Reliability,
		Suspects = clue.Suspects,
	})
end)

Players.PlayerRemoving:Connect(function(player)
	collectedEvidence[player.UserId] = nil
end)
