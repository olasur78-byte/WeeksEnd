local B = require(script.Parent.RigBuilder)
return {Id = "BogWalker", DisplayName = "The Bog Wolf", Create = function()
	local m, r = B.CreateBeast("BogWalker", "The Bog Wolf", Color3.fromRGB(159, 255, 95))
	B.Horns(m, r.Head, "antler")
	B.Attach(m, r.Torso, "MossMane", Vector3.new(1.1, 3.6, 0.5), Color3.fromRGB(30, 59, 29), CFrame.new(0, 0.5, 1.15))
	return m
end}