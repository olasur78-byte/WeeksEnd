local Players = game:GetService("Players")
local NPCProfiles = require(game.ReplicatedStorage.Modules.NPCProfiles)

local function randomizePlayerAppearance(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- Create a random HumanoidDescription
	local hd = NPCProfiles.createRandomDescription()

	-- Apply it
	local success, err = pcall(function()
		humanoid:ApplyDescription(hd)
	end)

	if not success then
		warn("PlayerAppearance: Failed to apply description:", err)
		-- Fallback: manual face change
		local head = character:FindFirstChild("Head")
		if head then
			local faceDecal = head:FindFirstChild("face")
			if faceDecal and faceDecal:IsA("Decal") then
				faceDecal.Texture = "rbxassetid://" .. tostring(NPCProfiles.randomFrom(NPCProfiles.Faces))
			end
		end
	end

	-- Set random body colors
	local bodyColors = character:FindFirstChild("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
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

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		randomizePlayerAppearance(character)
	end)
end

-- Handle existing players
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Handle new players
Players.PlayerAdded:Connect(onPlayerAdded)
