-- Add this as a Script in ServerScriptService.
-- The six monster ModuleScripts and RigBuilder must be in ServerStorage > MonsterRigs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local transformRemote = Remotes:WaitForChild("ToggleMonsterForm")
local RoundState = require(script.Parent:WaitForChild("RoundState"))
local monsterFolder = ServerStorage:WaitForChild("MonsterRigs")

local TRANSFORM_COOLDOWN = 8
local isMonsterForm = {}
local lastTransform = {}

local function currentCFrame(player)
	local character = player.Character
	if not character then
		return CFrame.new(0, 6, 0)
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return root and root.CFrame or CFrame.new(0, 6, 0)
end

local function becomeMonster(player, monsterId, position)
	local monsterModule = monsterFolder:FindFirstChild(monsterId)
	if not monsterModule or not monsterModule:IsA("ModuleScript") then
		warn("Monster module missing: " .. tostring(monsterId))
		return false
	end

	local oldCharacter = player.Character
	local monsterData = require(monsterModule)
	local monster = monsterData.Create()
	if not monster then
		return false
	end

	monster.Name = player.Name
	monster:SetAttribute("OwnerUserId", player.UserId)
	monster:SetAttribute("MonsterForm", true)
	monster:PivotTo(position)
	monster.Parent = workspace
	player.Character = monster

	if oldCharacter then
		oldCharacter:Destroy()
	end

	return true
end

local function becomeCivilian(player, position)
	player:LoadCharacter()
	local civilian = player.CharacterAdded:Wait()
	civilian:PivotTo(position)
end

transformRemote.OnServerEvent:Connect(function(player)
	if RoundState.GetRole(player) ~= "Kidnapper" then
		return
	end

	local now = os.clock()
	if now - (lastTransform[player] or 0) < TRANSFORM_COOLDOWN then
		return
	end
	lastTransform[player] = now

	local position = currentCFrame(player)
	if isMonsterForm[player] then
		isMonsterForm[player] = false
		becomeCivilian(player, position)
	else
		local monsterId = RoundState.GetMonster(player)
		if becomeMonster(player, monsterId, position) then
			isMonsterForm[player] = true
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	isMonsterForm[player] = nil
	lastTransform[player] = nil
end)