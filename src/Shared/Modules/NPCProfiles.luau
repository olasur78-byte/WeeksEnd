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

-- Free Roblox catalog hair accessory asset IDs
module.Hairs = {
	62247891,  -- Beautiful Hair
	63690008,  -- Pastel Hair
	16630171,  -- Brown Charmer Hair
	28583200,  -- The Classic
	62234125,  -- Spike Hair
	62724852,  -- Cinnamon Hair
	45201227,  -- Red Fabulous Hair
	62234473,  -- Lavender Hair
}

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

-- Random civilian names
module.Names = {
	"Alice", "Bob", "Carol", "David", "Emma", "Frank", "Grace", "Henry",
	"Iris", "Jack", "Karen", "Leo", "Mia", "Noah", "Olivia", "Paul",
	"Quinn", "Rachel", "Sam", "Tina", "Victor", "Wendy", "Xavier", "Yara",
	"Zack", "Amber", "Brian", "Chloe", "Derek", "Elena", "Felix", "Gina",
	"Hugo", "Ivy", "Jacob", "Kira", "Liam", "Maya", "Nina", "Oscar",
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

return module
