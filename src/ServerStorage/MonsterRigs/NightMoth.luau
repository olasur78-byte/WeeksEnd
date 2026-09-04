local B = require(script.Parent.RigBuilder)
return {Id = "NightMoth", DisplayName = "The Black Moth", Create = function()
	local m, r = B.CreateBeast("NightMoth", "The Black Moth", Color3.fromRGB(255, 35, 62))
	B.Attach(m, r.Torso, "LeftTornWing", Vector3.new(5.2, 0.2, 3.6), Color3.fromRGB(10, 10, 14), CFrame.new(-3.8, 0.6, 0.4))
	B.Attach(m, r.Torso, "RightTornWing", Vector3.new(5.2, 0.2, 3.6), Color3.fromRGB(10, 10, 14), CFrame.new(3.8, 0.6, 0.4))
	return m
end}