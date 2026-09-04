local B = require(script.Parent.RigBuilder)
return {Id = "NeonWisp", DisplayName = "The Starved Shade", Create = function()
	local m, r = B.CreateBeast("NeonWisp", "The Starved Shade", Color3.fromRGB(167, 72, 255))
	B.Horns(m, r.Head, "curved")
	B.Attach(m, r.Torso, "VoidMane", Vector3.new(1.3, 4.2, 0.45), Color3.fromRGB(30, 15, 50), CFrame.new(0, 0.8, 1.2))
	return m
end}