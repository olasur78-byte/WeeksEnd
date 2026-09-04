local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local definitions = {
	RoleAssigned = "RemoteEvent", RoundStateChanged = "RemoteEvent",
	CaseFileUpdated = "RemoteEvent", CellStateChanged = "RemoteEvent",
	CCTVMonitor = "RemoteEvent", BookingDesk = "RemoteEvent",
	StoreTransaction = "RemoteEvent", ToggleMonsterForm = "RemoteEvent",
	VictimStateChanged = "RemoteEvent", VictimTaskRequest = "RemoteEvent",
	MonsterTaskChanged = "RemoteEvent", SubmitMonsterGuess = "RemoteFunction",
	GetMyRole = "RemoteFunction", GetRoundSnapshot = "RemoteFunction",
}

for name, className in pairs(definitions) do
	if not remotes:FindFirstChild(name) then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remotes
	end
end
