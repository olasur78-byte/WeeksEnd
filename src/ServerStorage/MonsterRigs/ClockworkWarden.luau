local B = require(script.Parent.RigBuilder)
return {Id = "ClockworkWarden", DisplayName = "The Iron Maw", Create = function()
	local m, r = B.CreateBeast("ClockworkWarden", "The Iron Maw", Color3.fromRGB(70, 230, 255))
	B.Horns(m, r.Head, "curved")
	B.Attach(m, r.Torso, "ColdHeart", Vector3.new(0.8, 0.8, 0.24), Color3.fromRGB(55, 215, 255), CFrame.new(0, 0, -1), "Part", Enum.Material.Neon)
	return m
end}