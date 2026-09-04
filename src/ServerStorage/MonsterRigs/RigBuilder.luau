-- Beast V2: a darker, larger, animal-like replacement for the first rig pack.
local Builder = {}

local BLACK = Color3.fromRGB(12, 13, 16)
local FUR = Color3.fromRGB(24, 25, 30)
local BONE = Color3.fromRGB(205, 194, 166)

local function makePart(className, name, size, color, parent)
	local part = Instance.new(className or "Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.Fabric
	part.CanCollide = false
	part.Massless = true
	part.Parent = parent
	return part
end

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function motor(name, a, b, offset)
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = a
	m.Part1 = b
	m.C0 = offset
	m.Parent = a
end

function Builder.CreateBeast(id, name, eyeColor)
	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("MonsterId", id)
	model:SetAttribute("DisplayName", name)
	model:SetAttribute("IsMonsterRig", true)

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = name
	humanoid.WalkSpeed = 15
	humanoid.HipHeight = 2
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.Parent = model

	local root = makePart("Part", "HumanoidRootPart", Vector3.new(2, 2, 1), BLACK, model)
	root.Transparency = 1
	root.CFrame = CFrame.new(0, 6, 0)
	local torso = makePart("Part", "Torso", Vector3.new(3.2, 3.6, 1.8), BLACK, model)
	torso.CFrame = root.CFrame
	local head = makePart("Part", "Head", Vector3.new(2.8, 2.2, 2.1), FUR, model)
	head.CFrame = root.CFrame * CFrame.new(0, 2.55, -0.35)

	local leftArm = makePart("Part", "Left Arm", Vector3.new(1.25, 3.2, 1.25), BLACK, model)
	leftArm.CFrame = root.CFrame * CFrame.new(-2.2, -0.2, -0.25)
	local rightArm = makePart("Part", "Right Arm", Vector3.new(1.25, 3.2, 1.25), BLACK, model)
	rightArm.CFrame = root.CFrame * CFrame.new(2.2, -0.2, -0.25)
	local leftLeg = makePart("Part", "Left Leg", Vector3.new(1.45, 3.4, 1.45), BLACK, model)
	leftLeg.CFrame = root.CFrame * CFrame.new(-0.85, -3.45, 0.15)
	local rightLeg = makePart("Part", "Right Leg", Vector3.new(1.45, 3.4, 1.45), BLACK, model)
	rightLeg.CFrame = root.CFrame * CFrame.new(0.85, -3.45, 0.15)

	motor("RootJoint", root, torso, CFrame.new())
	motor("Neck", torso, head, CFrame.new(0, 2.55, -0.35))
	motor("Left Shoulder", torso, leftArm, CFrame.new(-2.2, -0.2, -0.25))
	motor("Right Shoulder", torso, rightArm, CFrame.new(2.2, -0.2, -0.25))
	motor("Left Hip", torso, leftLeg, CFrame.new(-0.85, -3.45, 0.15))
	motor("Right Hip", torso, rightLeg, CFrame.new(0.85, -3.45, 0.15))

	model.PrimaryPart = root
	Builder.Attach(model, head, "Muzzle", Vector3.new(2.15, 0.9, 1.5), FUR, CFrame.new(0, -0.35, -1.45))
	Builder.Eyes(model, head, eyeColor)
	Builder.Teeth(model, head)
	Builder.Fur(model, torso)
	Builder.Claws(model, leftArm)
	Builder.Claws(model, rightArm)
	return model, {Root = root, Torso = torso, Head = head, LeftArm = leftArm, RightArm = rightArm}
end

function Builder.Attach(model, target, name, size, color, offset, className, material)
	local p = makePart(className or "Part", name, size, color, model)
	p.Material = material or Enum.Material.Fabric
	p.CFrame = target.CFrame * offset
	weld(target, p)
	return p
end

function Builder.Eyes(model, head, color)
	for _, x in ipairs({-0.58, 0.58}) do
		local eye = Builder.Attach(model, head, "GlowingEye", Vector3.new(0.38, 0.42, 0.16), color, CFrame.new(x, 0.18, -1.1), "Part", Enum.Material.Neon)
		eye.Shape = Enum.PartType.Ball
	end
end

function Builder.Teeth(model, head)
	for _, x in ipairs({-0.72, -0.36, 0, 0.36, 0.72}) do
		Builder.Attach(model, head, "SharpTooth", Vector3.new(0.16, 0.48, 0.18), BONE, CFrame.new(x, -0.55, -2.15), "WedgePart", Enum.Material.SmoothPlastic)
	end
	local drool = Builder.Attach(model, head, "Drool", Vector3.new(0.13, 0.85, 0.13), Color3.fromRGB(130, 205, 220), CFrame.new(0.82, -0.85, -2.1), "Part", Enum.Material.Glass)
	drool.Shape = Enum.PartType.Ball
end

function Builder.Fur(model, torso)
	for _, z in ipairs({-0.5, 0, 0.5}) do
		local tuft = Builder.Attach(model, torso, "FurTuft", Vector3.new(0.75, 1.1, 0.4), FUR, CFrame.new(0, 2.1, z) * CFrame.Angles(0, 0, math.rad(45)), "WedgePart")
		tuft.Material = Enum.Material.Fabric
	end
end

function Builder.Claws(model, arm)
	for _, x in ipairs({-0.34, 0, 0.34}) do
		Builder.Attach(model, arm, "Claw", Vector3.new(0.18, 0.72, 0.22), BONE, CFrame.new(x, -1.75, -0.5), "WedgePart", Enum.Material.SmoothPlastic)
	end
end

function Builder.Horns(model, head, style)
	for _, x in ipairs({-1.05, 1.05}) do
		local direction = x < 0 and -1 or 1
		Builder.Attach(model, head, "Horn", Vector3.new(0.32, 2.3, 0.32), BONE, CFrame.new(x, 1.5, 0) * CFrame.Angles(0, 0, math.rad(25 * direction)), "Part", Enum.Material.SmoothPlastic)
		if style == "antler" then
			Builder.Attach(model, head, "AntlerBranch", Vector3.new(0.22, 1.0, 0.22), BONE, CFrame.new(x + 0.35 * direction, 2.15, 0) * CFrame.Angles(0, 0, math.rad(70 * direction)), "Part", Enum.Material.SmoothPlastic)
		end
	end
end

return Builder
