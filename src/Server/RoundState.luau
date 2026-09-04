local RoundState = {}

local rolesByPlayer = {}
local monstersByPlayer = {}
local round = {
	Id = 0, Phase = "Waiting", TimeOfDay = "Day", Kidnapper = nil,
	Victim = nil, House = nil, VictimRescued = false,
	MonsterIdentified = false, Winner = nil,
}

function RoundState.ClearPlayers()
	table.clear(rolesByPlayer)
	table.clear(monstersByPlayer)
	round.Kidnapper = nil
	round.Victim = nil
end

RoundState.ClearRoles = RoundState.ClearPlayers

function RoundState.Begin(assignment, house)
	round.Id += 1
	round.Phase = "Active"
	round.TimeOfDay = "Day"
	round.Kidnapper = assignment.Kidnapper
	round.Victim = assignment.Victim
	round.House = house
	round.VictimRescued = false
	round.MonsterIdentified = false
	round.Winner = nil
end

function RoundState.End(winner)
	round.Phase = "Ended"
	round.Winner = winner
end

function RoundState.GetSnapshot()
	return table.clone(round)
end

function RoundState.IsActive() return round.Phase == "Active" end
function RoundState.SetTimeOfDay(value) round.TimeOfDay = value end
function RoundState.IsDay() return round.TimeOfDay == "Day" end
function RoundState.MarkVictimRescued() round.VictimRescued = true end
function RoundState.MarkMonsterIdentified() round.MonsterIdentified = true end
function RoundState.CanPoliceWin() return round.VictimRescued and round.MonsterIdentified end

function RoundState.SetRole(player, role)
	rolesByPlayer[player] = role
	player:SetAttribute("RoundRole", role)
end

function RoundState.GetRole(player) return rolesByPlayer[player] end

function RoundState.SetMonster(player, monsterId)
	monstersByPlayer[player] = monsterId
	player:SetAttribute("MonsterId", monsterId)
end

function RoundState.GetMonster(player) return monstersByPlayer[player] end

function RoundState.PlayerRemoving(player)
	rolesByPlayer[player] = nil
	monstersByPlayer[player] = nil
end

return RoundState
