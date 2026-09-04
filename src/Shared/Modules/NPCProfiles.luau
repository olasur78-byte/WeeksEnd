local module = {}

-- Free Roblox catalog face asset IDs
module.Faces = {
	24829905,   -- Smile
	24829906,   -- Surprised
	24829907,   -- Sad
	24829908,   -- Cool
	24829909,   -- Mischevious
	24829910,   -- Laughing
	24829911,   -- Prankster
	60830846,   -- Happy
	2518531903, -- Stare
	2257210876, -- Spiral
	2162545536, -- Skeptical
	20757574,   -- Stitchface
	63389250,   -- Freckles
	97972674,   -- Surprise
	144075256,  -- Wink
	106193607,  -- Stoic
}

-- Verified HairAccessory assets from the Roblox catalog. The previous list
-- contained place/image IDs, which is why most masculine NPCs were bald.
module.Hairs = {
	2956239660, 63690008, 451221329, 1103003368, 16630147,
	376526888, 376524487, 376548738, 13745548, 727320877,
	323476364, 17877340,
}

module.FeminineHairs = { 2956239660, 16630147, 376526888, 13745548, 727320877, 323476364, 17877340 }
module.MasculineHairs = { 63690008, 451221329, 1103003368, 376524487, 376548738, 16630147 }

-- Classic clothing assets. Replace or extend these IDs with assets owned by the
-- experience if catalog permissions prevent loading a particular item.
module.Shirts = { 855766176, 855776103, 144076358, 398633584, 398633812 }
module.Pants = { 855777285, 855780781, 144076760, 398634295, 398635081 }

module.WitnessResponses = {
	"I noticed something unusual, but I only saw the person for a moment.",
	"They were trying very hard to behave like everyone else.",
	"I remember a strange sound and the direction they walked afterward.",
	"They visited one of the local businesses shortly before nightfall.",
}

-- Skin tone colors (RGB)
module.SkinTones = {
	Color3.fromRGB(255, 224, 189),
	Color3.fromRGB(241, 194, 145),
	Color3.fromRGB(224, 172, 105),
	Color3.fromRGB(198, 134, 66),
	Color3.fromRGB(141, 85, 36),
	Color3.fromRGB(255, 205, 148),
	Color3.fromRGB(232, 176, 169),
	Color3.fromRGB(180, 120, 80),
}

-- Shirt (torso) colors
module.ShirtColors = {
	Color3.fromRGB(200, 50, 50),
	Color3.fromRGB(50, 100, 200),
	Color3.fromRGB(50, 180, 80),
	Color3.fromRGB(200, 200, 50),
	Color3.fromRGB(150, 50, 200),
	Color3.fromRGB(200, 150, 50),
	Color3.fromRGB(50, 50, 50),
	Color3.fromRGB(240, 240, 240),
	Color3.fromRGB(100, 100, 100),
	Color3.fromRGB(180, 100, 100),
}

-- Pants (leg) colors
module.PantsColors = {
	Color3.fromRGB(50, 50, 80),
	Color3.fromRGB(40, 40, 40),
	Color3.fromRGB(100, 80, 60),
	Color3.fromRGB(60, 60, 100),
	Color3.fromRGB(80, 80, 80),
	Color3.fromRGB(50, 50, 50),
	Color3.fromRGB(100, 100, 120),
	Color3.fromRGB(70, 50, 40),
}

function module.randomFrom(tbl)
	return tbl[math.random(1, #tbl)]
end

function module.createRandomDescription()
	local hd = Instance.new("HumanoidDescription")
	hd.Face = module.randomFrom(module.Faces)
	hd.HairAccessory = tostring(module.randomFrom(module.Hairs))
	hd.Shirt = module.randomFrom(module.Shirts)
	hd.Pants = module.randomFrom(module.Pants)
	return hd
end

function module.createReliableNPCDescription()
	local hd = Instance.new("HumanoidDescription")
	-- Keep the generated rig independent from catalog delivery. Several of the
	-- old free assets can fail moderation/loading and leave an entirely black
	-- avatar. BodyColors are applied after the rig is created.
	hd.HeadColor = module.randomFrom(module.SkinTones)
	hd.LeftArmColor = hd.HeadColor
	hd.RightArmColor = hd.HeadColor
	hd.TorsoColor = module.randomFrom(module.ShirtColors)
	local pantsColor = module.randomFrom(module.PantsColors)
	hd.LeftLegColor = pantsColor
	hd.RightLegColor = pantsColor
	return hd
end

function module.createCivilianProfile()
	local presentation = if math.random() < 0.5 then "Feminine" else "Masculine"
	local hd = module.createReliableNPCDescription()

	-- Hair and classic clothing add variety, while the body colors above remain
	-- a readable fallback if an individual catalog texture is unavailable.
	local hairPool = if presentation == "Feminine" then module.FeminineHairs else module.MasculineHairs
	hd.HairAccessory = tostring(module.randomFrom(hairPool))
	hd.Face = module.randomFrom(module.Faces)
	hd.Shirt = module.randomFrom(module.Shirts)
	hd.Pants = module.randomFrom(module.Pants)

	if presentation == "Feminine" then
		hd.BodyTypeScale = math.random(25, 55) / 100
		hd.ProportionScale = math.random(45, 80) / 100
		hd.HeightScale = math.random(92, 103) / 100
		hd.WidthScale = math.random(78, 94) / 100
	else
		hd.BodyTypeScale = math.random(0, 35) / 100
		hd.ProportionScale = math.random(15, 55) / 100
		hd.HeightScale = math.random(96, 108) / 100
		hd.WidthScale = math.random(88, 105) / 100
	end

	return hd, presentation
end

return module
