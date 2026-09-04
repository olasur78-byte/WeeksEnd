local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local caseFileUpdatedRemote = ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("CaseFileUpdated")

caseFileUpdatedRemote.OnClientEvent:Connect(function(data)
	local message = data.Description

	if data.Reliability then
		message = message .. " [" .. data.Reliability .. " reliability]"
	end

	StarterGui:SetCore("SendNotification", {
		Title = data.Title or "Case File Updated",
		Text = message,
		Duration = 7,
	})
end)