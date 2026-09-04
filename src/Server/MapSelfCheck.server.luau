local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Other server scripts initialize some runtime objects in parallel. Give them one
-- scheduler turn before inspecting the finished place.
task.wait(2)

local errors = {}
local warnings = {}

local function fail(message)
	table.insert(errors, message)
end

local function caution(message)
	table.insert(warnings, message)
end

local function countTagged(tag, minimum)
	local count = #CollectionService:GetTagged(tag)
	if count < minimum then
		fail(string.format("tag %q: found %d, expected at least %d", tag, count, minimum))
	end
	return count
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local expectedRemotes = {
	RoleAssigned = "RemoteEvent", RoundStateChanged = "RemoteEvent",
	CaseFileUpdated = "RemoteEvent", CellStateChanged = "RemoteEvent",
	CCTVMonitor = "RemoteEvent", BookingDesk = "RemoteEvent",
	StoreTransaction = "RemoteEvent", ToggleMonsterForm = "RemoteEvent",
	VictimStateChanged = "RemoteEvent", VictimTaskRequest = "RemoteEvent",
	MonsterTaskChanged = "RemoteEvent", MonsterDialogueChoice = "RemoteEvent",
	SubmitMonsterGuess = "RemoteFunction", GetMyRole = "RemoteFunction",
	GetRoundSnapshot = "RemoteFunction",
}

if not remotes then
	fail("ReplicatedStorage.Remotes is missing")
else
	for name, className in expectedRemotes do
		local remote = remotes:FindFirstChild(name)
		if not remote or remote.ClassName ~= className then
			fail(string.format("Remotes.%s must be a %s", name, className))
		end
	end
end

local modules = ReplicatedStorage:FindFirstChild("Modules")
for _, name in { "GameConfig", "RoleConfig", "NPCProfiles", "EvidenceDefinitions" } do
	if not modules or not modules:FindFirstChild(name) then
		fail("ReplicatedStorage.Modules." .. name .. " is missing")
	end
end

local tagCounts = {
	KidnapHouse = countTagged("KidnapHouse", 1),
	RoundSpawn = countTagged("RoundSpawn", 1),
	BasementZone = countTagged("BasementZone", 1),
	PoliceStationZone = countTagged("PoliceStationZone", 1),
}

for _, house in CollectionService:GetTagged("KidnapHouse") do
	if not (house:FindFirstChild("KidnapSpawn", true) or house:FindFirstChild("BasementSpawn", true) or house:FindFirstChild("BF", true)) then
		fail(house:GetFullName() .. " has no KidnapSpawn, BasementSpawn, or BF")
	end
end

local npcSpawnCount = #CollectionService:GetTagged("NPCStreet")
if npcSpawnCount == 0 then
	for _, child in workspace:GetDescendants() do
		if child:IsA("BasePart") then
			local name = child.Name:lower()
			if name:find("road", 1, true) or name:find("street", 1, true)
				or name:find("sidewalk", 1, true) or name:find("pavement", 1, true)
				or name:find("asphalt", 1, true) then
				npcSpawnCount += 1
			end
		end
	end
end
if npcSpawnCount == 0 then
	fail("no NPC street surfaces found; tag road or sidewalk parts with NPCStreet")
end

local attributeCounts = {
	VictimTask = 0, SupplyType = 0, EvidenceKind = 0, MonsterActivity = 0, CCTV = 0,
}
local validValues = {
	VictimTask = { LockpickCraft = true, DoorPuzzle = true, RoomPuzzle = true, FinalDoor = true },
	SupplyType = { Food = true, Water = true },
	EvidenceKind = { Visual = true, Witness = true, Physical = true },
	MonsterActivity = { Groceries = true, Pharmacy = true, PoliceQuestioning = true },
}

for _, instance in workspace:GetDescendants() do
	for attribute, allowed in validValues do
		local value = instance:GetAttribute(attribute)
		if value ~= nil then
			attributeCounts[attribute] += 1
			if not allowed[value] then
				fail(string.format("%s has invalid %s=%s", instance:GetFullName(), attribute, tostring(value)))
			end
		end
	end
	if instance:IsA("BasePart") and instance:GetAttribute("EvidenceType") == "CCTV" then
		attributeCounts.CCTV += 1
		if instance:GetAttribute("CameraId") == nil or instance:GetAttribute("Location") == nil then
			fail(instance:GetFullName() .. " is CCTV but lacks CameraId or Location")
		end
	end
end

for _, attribute in { "VictimTask", "MonsterActivity" } do
	if attributeCounts[attribute] == 0 then
		caution("no objects use the " .. attribute .. " attribute")
	end
end
if attributeCounts.CCTV == 0 then
	caution("no CCTV camera parts were found")
end

local summary = string.format(
	"tags: %d houses, %d round spawns, %d basements, %d police zones; NPC spawns: %d; CCTV: %d",
	tagCounts.KidnapHouse, tagCounts.RoundSpawn, tagCounts.BasementZone,
	tagCounts.PoliceStationZone, npcSpawnCount, attributeCounts.CCTV
)

if #errors == 0 then
	print("[SELF CHECK] PASS - " .. summary)
else
	warn(string.format("[SELF CHECK] FAIL (%d errors) - %s", #errors, summary))
	for index, message in errors do
		warn(string.format("[SELF CHECK][ERROR %d] %s", index, message))
	end
end
for index, message in warnings do
	warn(string.format("[SELF CHECK][WARNING %d] %s", index, message))
end
