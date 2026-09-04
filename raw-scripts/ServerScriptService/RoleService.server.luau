local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RoundState = require(script.Parent:WaitForChild("RoundState"))

local roleAssignedRemote = Remotes:WaitForChild("RoleAssigned")
local roundStateRemote = Remotes:WaitForChild("RoundStateChanged")

local monsterIds = {
	"NightMoth",
	"HollowMimic",
	"AntlerStalker",
	"ClockworkWarden",
	"BogWalker",
	"NeonWisp",
}

local function shuffle(list)
	for i = #list, 2, -1 do
		local randomIndex = math.random(1, i)
		list[i], list[randomIndex] = list[randomIndex], list[i]
	end
end

local function assignRoles()
	local party = Players:GetPlayers()

	if #party < 3 then
		return
	end

	shuffle(party)
	RoundState.ClearRoles()

	local kidnapper = party[1]
	local kidnapped = party[2]
	local monsterId = monsterIds[math.random(1, #monsterIds)]

	RoundState.SetRole(kidnapper, "Kidnapper")
	RoundState.SetMonster(kidnapper, monsterId)
	roleAssignedRemote:FireClient(kidnapper, "Kidnapper", monsterId)

	RoundState.SetRole(kidnapped, "Kidnapped")
	roleAssignedRemote:FireClient(kidnapped, "Kidnapped")

	for index = 3, #party do
		local detective = party[index]
		RoundState.SetRole(detective, "Detective")
		roleAssignedRemote:FireClient(detective, "Detective")
	end

	roundStateRemote:FireAllClients("RoundStarted")
	print("Roles successfully assigned to " .. #party .. " players.")
end

while #Players:GetPlayers() < 3 do
	task.wait(1)
end

task.wait(3)
assignRoles()