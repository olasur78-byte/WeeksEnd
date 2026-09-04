return {
	Needs = {
		MinimumSupply = 35,
		MaximumSupply = 75,
		HungerLossPerMinute = 7,
		ThirstLossPerMinute = 10,
		DamageAtZero = 5,
	},
	VictimTasks = {
		LockpickCraft = { Duration = 12, Resettable = true },
		DoorPuzzle = { Duration = 18, Resettable = true },
		RoomPuzzle = { Duration = 25, Resettable = false },
		FinalDoor = { Duration = 15, Resettable = true },
	},
	Monster = { RequiredDayActivities = 2, NightKillsRequired = 1, InteractionCooldown = 1 },
	Zones = {
		BasementTag = "BasementZone",
		PoliceStationTag = "PoliceStationZone",
		RoundHouseTag = "KidnapHouse",
		SpawnTag = "RoundSpawn",
	},
}
