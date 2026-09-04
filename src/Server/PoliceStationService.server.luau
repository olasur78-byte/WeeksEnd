local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local EvidenceDefinitions = require(Modules:WaitForChild("EvidenceDefinitions"))
local RoundState = require(script.Parent:WaitForChild("RoundState"))

local caseFileUpdatedRemote = Remotes:WaitForChild("CaseFileUpdated")
local cellStateRemote = Remotes:WaitForChild("CellStateChanged")
local cctvMonitorRemote = Remotes:WaitForChild("CCTVMonitor")
local bookingDeskRemote = Remotes:WaitForChild("BookingDesk")

-- Track cell states (open/closed)
local cellStates = {
	[0] = false, -- Cell 0 starts closed
	[1] = false, -- Cell 1 starts closed
}

-- Track collected evidence per player for the monitoring desk
local monitoredEvidence = {}

-- Track booked suspects
local bookedSuspects = {}

local function isNearPart(player, part, maxDist)
	local character = player.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	return (root.Position - part.Position).Magnitude <= maxDist + 3
end

local function getCellBars(cellNumber)
	local map = game.Workspace:FindFirstChild("Map")
	local police = map and map:FindFirstChild("PoliceStation")
	if not police then return {} end

	local bars = {}
	for i = 0, 4 do
		local bar = police:FindFirstChild("Bar" .. cellNumber .. "_" .. i)
		if bar then
			table.insert(bars, bar)
		end
	end
	return bars
end

local function toggleCell(cellNumber)
	local bars = getCellBars(cellNumber)
	if #bars == 0 then return false end

	cellStates[cellNumber] = not cellStates[cellNumber]
	local isOpen = cellStates[cellNumber]

	for _, bar in ipairs(bars) do
		bar.CanCollide = not isOpen
		bar.Transparency = isOpen and 0.7 or 0
	end

	return isOpen
end

local function sendEvidence(player, evidence)
	monitoredEvidence[player.UserId] = monitoredEvidence[player.UserId] or {}
	local evidenceId = tostring(RoundState.GetSnapshot().Id) .. "_" .. evidence.Id
	if monitoredEvidence[player.UserId][evidenceId] then
		caseFileUpdatedRemote:FireClient(player, {
			Type = "AlreadyCollected",
			Title = "Case File",
			Description = "You already reviewed this footage.",
		})
		return
	end
	monitoredEvidence[player.UserId][evidenceId] = true
	caseFileUpdatedRemote:FireClient(player, {
			Type = "Evidence",
		Id = evidenceId,
			Title = evidence.Title,
			Description = evidence.Description,
		Reliability = evidence.Reliability,
		Suspects = evidence.Suspects,
	})
end

local function getAllCCTVCameras()
	local cameras = {}
	local map = game.Workspace:FindFirstChild("Map")
	if not map then return cameras end
	-- Find all CameraBody parts with CCTV EvidenceType attribute
	for _, descendant in ipairs(map:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("EvidenceType") == "CCTV" then
			local cameraId = descendant:GetAttribute("CameraId")
			local location = descendant:GetAttribute("Location")
			if cameraId and location then
					table.insert(cameras, {
						CameraId = cameraId,
						Location = location,
						Position = descendant.Position,
						CFrame = descendant.CFrame,
					})
			end
		end
	end
	return cameras
end

-- Handle all ProximityPrompts in the police station
ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
	local parent = prompt.Parent
	if not parent or not parent:IsA("BasePart") then return end

	local map = game.Workspace:FindFirstChild("Map")
	local police = map and map:FindFirstChild("PoliceStation")
	if not police then return end

	-- Check if the prompt is inside the police station
	local ancestor = parent
	local inStation = false
	while ancestor do
		if ancestor == police then
			inStation = true
			break
		end
		ancestor = ancestor.Parent
	end
	if not inStation then return end

	local role = RoundState.GetRole(player)

	-- Booking Desk: Book a suspect
	if parent.Name == "Desk" then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		if role ~= "Detective" then
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Booking Desk",
				Description = "Only detectives can book suspects.",
			})
			return
		end

		-- Check if a player is near the desk to be booked
		local nearestSuspect = nil
		local nearestDist = 15
		for _, otherPlayer in Players:GetPlayers() do
			if otherPlayer ~= player then
				local otherRole = RoundState.GetRole(otherPlayer)
				if otherRole == "Kidnapper" then
					local otherChar = otherPlayer.Character
					if otherChar then
						local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
						if otherRoot then
							local dist = (otherRoot.Position - parent.Position).Magnitude
							if dist < nearestDist then
								nearestSuspect = otherPlayer
								nearestDist = dist
							end
						end
					end
				end
			end
		end

		if nearestSuspect then
			bookedSuspects[nearestSuspect.UserId] = true
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Suspect Booked",
				Description = nearestSuspect.Name .. " has been booked and placed in the system. Escort them to a holding cell.",
			})
			caseFileUpdatedRemote:FireClient(nearestSuspect, {
				Type = "Info",
				Title = "You Have Been Booked",
				Description = "You have been booked by a detective. You must comply and be escorted to a holding cell.",
			})
		else
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Booking Desk",
				Description = "No suspects nearby to book. Bring a suspect to the desk first.",
			})
		end
		return
	end

	-- Holding Cell Toggle (BarTop0 = Cell 0, BarTop1 = Cell 1)
	if parent.Name == "BarTop0" or parent.Name == "BarTop1" then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		local cellNumber = parent:GetAttribute("CellNumber")
		if cellNumber == nil then return end

		local isOpen = toggleCell(cellNumber)

		caseFileUpdatedRemote:FireClient(player, {
			Type = "Info",
			Title = "Holding Cell " .. (cellNumber + 1),
			Description = isOpen and "Cell door opened." or "Cell door closed.",
		})

		cellStateRemote:FireAllClients(cellNumber, isOpen)
		return
	end

	-- Evidence Locker: Review collected evidence
	if parent.Name == "EvLocker" then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		if role ~= "Detective" then
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "Evidence Locker",
				Description = "Only detectives can access the evidence locker.",
			})
			return
		end

		local evidenceCount = 0
		if monitoredEvidence[player.UserId] then
			for _ in pairs(monitoredEvidence[player.UserId]) do
				evidenceCount = evidenceCount + 1
			end
		end

		caseFileUpdatedRemote:FireClient(player, {
			Type = "Info",
			Title = "Evidence Locker",
			Description = "The locker contains " .. evidenceCount .. " pieces of reviewed evidence. Continue investigating to find more clues.",
		})
		return
	end

	-- CCTV Monitoring Desk: Access all camera feeds
	if parent.Name == "MonDesk" then
		if not isNearPart(player, parent, prompt.MaxActivationDistance) then return end

		if role ~= "Detective" then
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info",
				Title = "CCTV Control",
				Description = "Only detectives can access the camera system.",
			})
			return
		end

		if not RoundState.IsDay() then
			caseFileUpdatedRemote:FireClient(player, {
				Type = "Info", Title = "CCTV offline",
				Description = "Camera feeds are unavailable at night.",
			})
			cctvMonitorRemote:FireClient(player, {}, false)
			return
		end

		-- Send all camera data to the client
		local cameras = getAllCCTVCameras()
		cctvMonitorRemote:FireClient(player, cameras, true)

		-- One camera contains a round-specific visual clue. Other feeds remain useful
		-- for observing live movement without flooding the case file.
		if cameras[1] then
			local snapshot = RoundState.GetSnapshot()
			local clue = EvidenceDefinitions.ForMonster(RoundState.GetMonster(snapshot.Kidnapper), "Visual")
			if clue then sendEvidence(player, clue) end
		end
		return
	end
end)

Players.PlayerRemoving:Connect(function(player)
	monitoredEvidence[player.UserId] = nil
	bookedSuspects[player.UserId] = nil
end)
