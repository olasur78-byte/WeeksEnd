local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local EvidenceDefinitions = require(Modules:WaitForChild("EvidenceDefinitions"))
local RoundState = require(script.Parent:WaitForChild("RoundState"))

local caseFileUpdatedRemote = Remotes:WaitForChild("CaseFileUpdated")
local storeTransactionRemote = Remotes:WaitForChild("StoreTransaction")

-- Track player coins and collected store evidence
local playerCoins = {}
local collectedStoreEvidence = {}

local STARTING_COINS = 50

local function getCoins(player)
	return playerCoins[player.UserId] or STARTING_COINS
end

local function setCoins(player, amount)
	playerCoins[player.UserId] = amount
end

local function isNearPart(player, part, maxDist)
	local character = player.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position - part.Position).Magnitude <= maxDist + 3
end

local function sendEvidence(player, evidence)
	collectedStoreEvidence[player.UserId] = collectedStoreEvidence[player.UserId] or {}
	if collectedStoreEvidence[player.UserId][evidence.Id] then
		caseFileUpdatedRemote:FireClient(player, {
			Type = "AlreadyCollected",
			Title = "Case File",
			Description = "You already collected this evidence.",
		})
		return
	end
	collectedStoreEvidence[player.UserId][evidence.Id] = true
	caseFileUpdatedRemote:FireClient(player, {
			Type = "Evidence",
			Id = evidence.Id,
			Title = evidence.Title,
			Description = evidence.Description,
			Reliability = evidence.Reliability,
		})
end

-- Handle all ProximityPrompts in the convenience store
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local parent = prompt.Parent
	if not parent or not parent:IsA("BasePart") then return end

	local map = game.Workspace:FindFirstChild("Map")
	local store = map and map:FindFirstChild("ConvenienceStore")
	if not store then return end

	-- Check if the prompt is inside the convenience store
	local ancestor = parent
	local inStore = false
	while ancestor do
		if ancestor == store then
			inStore = true
			break
		end
		ancestor = ancestor.Parent
	end
	if not inStore then return end

	-- Cash Register: Show transaction log as evidence
	if parent.Name == "CashRegister" then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		local role = RoundState.GetRole(player)
		if role ~= "Detective" then
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Cash Register",
				Description = "The register is locked. Only authorized personnel can review transactions.",
			})
			return
		end

		sendEvidence(player, EvidenceDefinitions.StoreTransactions)
		return
	end

	-- Products: Purchase items
	if parent:GetAttribute("IsProduct") then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		local price = parent:GetAttribute("ProductPrice") or 0
		local coins = getCoins(player)

		-- Newspaper gives evidence clue
		if parent.Name == "Newspaper" then
			local role = RoundState.GetRole(player)
			if role == "Detective" then
				sendEvidence(player, EvidenceDefinitions.Newspaper)
			else
				caseFileUpdatedRemote:FireClient(player, {
					Type = "Info",
					Title = "Newspaper",
					Description = "The front page mentions recent disappearances in the area...",
				})
			end
			return
		end

		-- Regular product purchase
		if coins >= price then
			setCoins(player, coins - price)
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Purchase",
				Title = "Purchase Successful",
				Description = "You bought " .. parent.Name .. " for " .. price .. " coins. Remaining: " .. (coins - price) .. " coins.",
			})
		else
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Insufficient Funds",
				Description = "You need " .. price .. " coins to buy " .. parent.Name .. ". You have " .. coins .. " coins.",
			})
		end
		return
	end
end)

-- Initialize coins for new players
Players.PlayerAdded:Connect(function(player)
	playerCoins[player.UserId] = STARTING_COINS
end)

for _, player in Players:GetPlayers() do
	playerCoins[player.UserId] = STARTING_COINS
end

Players.PlayerRemoving:Connect(function(player)
	playerCoins[player.UserId] = nil
	collectedStoreEvidence[player.UserId] = nil
end)
