-- Procedural animation for HollowMimic monster rig
-- Animates leg Motor6D joints with a quadrupedal walk cycle

local RunService = game:GetService("RunService")
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Leg joint configuration: {partName, phaseOffset, maxAngleDegrees}
-- Front-left + rear-right in phase; front-right + rear-left 180 offset
local LEG_JOINTS = {
	-- Upper legs (swing forward/back)
	{"FRONT_-1_UPPER", 0, 22},
	{"FRONT_1_UPPER", math.pi, 22},
	{"REAR_-1_UPPER", math.pi, 22},
	{"REAR_1_UPPER", 0, 22},
	{"REAR_-1_THIGH", math.pi, 20},
	{"REAR_1_THIGH", 0, 20},
	-- Lower legs (knee bend, ~90 deg offset from upper)
	{"FRONT_-1_LOWER", math.pi * 0.5, 30},
	{"FRONT_1_LOWER", math.pi * 1.5, 30},
	{"REAR_-1_LOWER", math.pi * 1.5, 30},
	{"REAR_1_LOWER", math.pi * 0.5, 30},
	{"REAR_-1_KNEE", math.pi * 1.5, 25},
	{"REAR_1_KNEE", math.pi * 0.5, 25},
}

-- Subtle body movement for natural feel
local BODY_JOINTS = {
	{"NECK_MAIN", 0, 4},
	{"HEAD_SKULL", 0, 3},
	{"TAIL_MAIN", 0, 12},
	{"BODY_MAIN", 0, 2},
}

-- Find Motor6D for a given part name
local function findMotor(partName)
	local part = character:FindFirstChild(partName)
	if not part then return nil end
	return part:FindFirstChildOfClass("Motor6D")
end

-- Collect leg joints
local legJoints = {}
for _, info in ipairs(LEG_JOINTS) do
	local motor = findMotor(info[1])
	if motor then
		table.insert(legJoints, {
			motor = motor,
			initialC0 = motor.C0,
			phase = info[2],
			maxAngle = info[3],
		})
	end
end

-- Collect body joints
local bodyJoints = {}
for _, info in ipairs(BODY_JOINTS) do
	local motor = findMotor(info[1])
	if motor then
		table.insert(bodyJoints, {
			motor = motor,
			initialC0 = motor.C0,
			phase = info[2],
			maxAngle = info[3],
		})
	end
end

-- Disable default Animate script to prevent conflicts
local function disableAnimate()
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("LocalScript") and child.Name == "Animate" then
			child.Enabled = false
		end
	end
end
disableAnimate()
character.ChildAdded:Connect(function(child)
	if child:IsA("LocalScript") and child.Name == "Animate" then
		task.wait(0.1)
		child.Enabled = false
	end
end)

-- Animation state
local elapsed = 0
local smoothedSpeed = 0

RunService.RenderStepped:Connect(function(dt)
	if not humanoid or humanoid.Health <= 0 then return end
	if not rootPart or not rootPart.Parent then return end

	elapsed = elapsed + dt

	-- Calculate horizontal speed
	local velocity = rootPart.AssemblyLinearVelocity
	local horizontalSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
	smoothedSpeed = smoothedSpeed * 0.85 + horizontalSpeed * 0.15

	local isMoving = smoothedSpeed > 1.5
	local walkFreq = 6
	local intensity = math.clamp(smoothedSpeed / 8, 0, 1)

	if isMoving and intensity > 0.05 then
		local phase = elapsed * walkFreq

		for _, joint in ipairs(legJoints) do
			local angle = math.sin(phase + joint.phase) * joint.maxAngle * intensity
			joint.motor.C0 = joint.initialC0 * CFrame.Angles(math.rad(angle), 0, 0)
		end

		for _, joint in ipairs(bodyJoints) do
			local angle = math.sin(phase * 0.5 + joint.phase) * joint.maxAngle * intensity
			joint.motor.C0 = joint.initialC0 * CFrame.Angles(math.rad(angle), 0, 0)
		end
	else
		-- Idle: smooth return to initial pose with subtle breathing
		local idlePhase = elapsed * 1.5
		local breath = math.sin(idlePhase) * 2

		for _, joint in ipairs(legJoints) do
			joint.motor.C0 = joint.motor.C0:Lerp(joint.initialC0, dt * 8)
		end

		for _, joint in ipairs(bodyJoints) do
			local angle = breath * (joint.maxAngle / 5)
			joint.motor.C0 = joint.initialC0 * CFrame.Angles(math.rad(angle), 0, 0)
		end
	end
end)