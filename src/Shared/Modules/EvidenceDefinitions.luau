local EvidenceDefinitions = {
	Monsters = {
		NightMoth = {
			Visual = "Fine grey wing-dust caught on a window frame.",
			Witness = "The suspect avoided bright lamps and kept rubbing their eyes.",
			Physical = "A torn fabric edge carries powdery scales rather than fur.",
		},
		HollowMimic = {
			Visual = "The figure's reflection moved a fraction later than its body.",
			Witness = "Their voice copied a neighbour perfectly, but used the wrong name.",
			Physical = "A flexible strip resembling artificial skin was left behind.",
		},
		AntlerStalker = {
			Visual = "Two narrow scratches appear above the height of a normal doorway.",
			Witness = "A tall silhouette ducked under the porch despite appearing human.",
			Physical = "A splinter is marked by a hard, branching impact.",
		},
		ClockworkWarden = {
			Visual = "The camera recorded a regular metallic twitch every four seconds.",
			Witness = "A quiet ticking followed the suspect after they stopped walking.",
			Physical = "A trace of dark machine oil was found beside the footprint.",
		},
		BogWalker = {
			Visual = "Wet prints remain although the street had been dry all evening.",
			Witness = "The suspect smelled of stagnant water and damp soil.",
			Physical = "Marsh moss and black mud cling to the recovered fibre.",
		},
		NeonWisp = {
			Visual = "A brief coloured glow appears without a matching light source.",
			Witness = "Nearby electronics flickered whenever the suspect became nervous.",
			Physical = "The sample holds a weak static charge and faint blue luminescence.",
		},
	},
	CCTV = {
		StoreCamera01 = {
			Id = "cctv_store_01",
			Title = "Store CCTV — 8:12 PM",
			Description = "A resident wearing a blue jacket and carrying a black backpack entered the alley behind the store.",
			Reliability = "High",
		},
		PoliceCamera01 = {
			Id = "cctv_police_01",
			Title = "Entrance Camera — 9:45 PM",
			Description = "A figure was seen lingering near the police station entrance, watching the parking lot before walking toward the residential area.",
			Reliability = "Medium",
		},
		PoliceCamera02 = {
			Id = "cctv_police_02",
			Title = "Cell Block Camera — 11:30 PM",
			Description = "The holding cells appear empty, but a shadow moves past the cell block corridor toward the back exit.",
			Reliability = "Medium",
		},
		PoliceCamera03 = {
			Id = "cctv_police_03",
			Title = "Lobby Camera — 7:50 PM",
			Description = "A nervous individual entered the lobby, asked the desk officer a question, then left quickly heading east.",
			Reliability = "High",
		},
		StreetCamera01 = {
			Id = "cctv_street_01",
			Title = "Street Camera — 8:30 PM",
			Description = "A vehicle with a broken taillight was parked on the north end of the street for over an hour before driving off toward the convenience store.",
			Reliability = "High",
		},
	},

	StoreTransactions = {
		Id = "store_transactions",
		Title = "Cash Register Log — 8:15 PM",
		Description = "The register shows a cash purchase of duct tape, rope, and a large duffel bag at 8:15 PM. No loyalty card was used.",
		Reliability = "High",
	},

	Newspaper = {
		Id = "newspaper_clue",
		Title = "Today's Newspaper",
		Description = "The front page reports a series of disappearances in the neighborhood. The last known sighting was near the convenience store.",
		Reliability = "Medium",
	},
}

function EvidenceDefinitions.ForMonster(monsterId, evidenceKind)
	local profile = EvidenceDefinitions.Monsters[monsterId]
	if not profile then return nil end
	local description = profile[evidenceKind]
	if not description then return nil end
	return {
		Id = string.lower(monsterId) .. "_" .. string.lower(evidenceKind),
		Title = evidenceKind .. " evidence",
		Description = description,
		Reliability = evidenceKind == "Physical" and "High" or "Medium",
		Suspects = { monsterId },
	}
end

return EvidenceDefinitions
