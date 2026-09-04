local RoundState = {}

local rolesByPlayer = {}
local monstersByPlayer = {}

function RoundState.ClearRoles()
	table.clear(rolesByPlayer)
	table.clear(monstersByPlayer)
end

function RoundState.SetRole(player, role)
	rolesByPlayer[player] = role
end

function RoundState.GetRole(player)
	return rolesByPlayer[player]
end

function RoundState.SetMonster(player, monsterId)
	monstersByPlayer[player] = monsterId
end

function RoundState.GetMonster(player)
	return monstersByPlayer[player]
end

return RoundState