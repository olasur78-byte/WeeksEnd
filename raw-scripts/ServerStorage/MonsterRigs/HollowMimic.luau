local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local monsterRigs = ServerStorage:WaitForChild("MonsterRigs")

return {
	Id = "HollowMimic",
	DisplayName = "The Hollow Mimic",
	Create = function()
		local template = monsterRigs:FindFirstChild("HollowMimicTemplate")
		if not template then
			warn("HollowMimicTemplate not found in ServerStorage.MonsterRigs")
			return nil
		end

		local monster = template:Clone()

		-- Remove AnimationController; the Humanoid's Animator will handle animations
		local animController = monster:FindFirstChildOfClass("AnimationController")
		if animController then
			animController.Parent = nil
		end

		-- Rename RootPart to HumanoidRootPart for player character compatibility
		local rootPart = monster:FindFirstChild("RootPart")
		if rootPart then
			rootPart.Name = "HumanoidRootPart"
			rootPart.CanCollide = false
			monster.PrimaryPart = rootPart
		end

		-- Add Humanoid for player control
		local humanoid = Instance.new("Humanoid")
		humanoid.DisplayName = "The Hollow Mimic"
		humanoid.WalkSpeed = 16
		humanoid.HipHeight = 0
		humanoid.Parent = monster

		monster:SetAttribute("MonsterId", "HollowMimic")
		monster:SetAttribute("DisplayName", "The Hollow Mimic")

		-- Attach procedural animation script
		local animatorTemplate = ReplicatedStorage:FindFirstChild("HollowMimicAnimator")
		if animatorTemplate and animatorTemplate:IsA("LocalScript") then
			local animator = animatorTemplate:Clone()
			animator.Parent = monster
		end

		return monster
	end,
}
