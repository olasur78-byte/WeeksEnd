local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoleConfig = require(ReplicatedStorage.Modules.RoleConfig)

local RoleService = {}

local function shuffledPlayers()
	local party = Players:GetPlayers()
	for index = #party, 2, -1 do
		local other = math.random(1, index)
		party[index], party[other] = party[other], party[index]
	end
	return party
end

function RoleService.Assign(roundState)
	local party = shuffledPlayers()
	if #party < RoleConfig.MinPlayers then
		return nil
	end

	local kidnapper = party[1]
	local victim = party[2]
	local monsterId = RoleConfig.Monsters[math.random(1, #RoleConfig.Monsters)]

	roundState.ClearPlayers()
	roundState.SetRole(kidnapper, RoleConfig.Roles.Kidnapper)
	roundState.SetMonster(kidnapper, monsterId)
	roundState.SetRole(victim, RoleConfig.Roles.Kidnapped)

	for index = 3, #party do
		roundState.SetRole(party[index], RoleConfig.Roles.Detective)
	end

	return { Players = party, Kidnapper = kidnapper, Victim = victim, MonsterId = monsterId }
end

return RoleService
