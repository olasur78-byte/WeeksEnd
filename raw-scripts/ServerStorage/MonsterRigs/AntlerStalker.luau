local B = require(script.Parent.RigBuilder)
return {Id = "AntlerStalker", DisplayName = "The Antler Stalker", Create = function()
	local m, r = B.CreateBeast("AntlerStalker", "The Antler Stalker", Color3.fromRGB(244, 219, 92))
	B.Horns(m, r.Head, "antler")
	return m
end}