local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local caseFileUpdatedRemote = Remotes:WaitForChild("CaseFileUpdated")
local cctvMonitorRemote = Remotes:WaitForChild("CCTVMonitor")
local cellStateRemote = Remotes:WaitForChild("CellStateChanged")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local previousCameraType = nil
local previousCameraSubject = nil

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CityUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Notification frame
local notifFrame = Instance.new("Frame")
notifFrame.Name = "NotificationFrame"
notifFrame.Size = UDim2.new(0, 400, 0, 120)
notifFrame.Position = UDim2.new(0.5, -200, 0.2, 0)
notifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
notifFrame.BackgroundTransparency = 0.1
notifFrame.BorderSizePixel = 2
notifFrame.BorderColor3 = Color3.fromRGB(60, 120, 200)
notifFrame.Visible = false
notifFrame.Parent = screenGui

local notifCorner = Instance.new("UICorner")
notifCorner.CornerRadius = UDim.new(0, 8)
notifCorner.Parent = notifFrame

local notifTitle = Instance.new("TextLabel")
notifTitle.Name = "Title"
notifTitle.Size = UDim2.new(1, -20, 0, 30)
notifTitle.Position = UDim2.new(0, 10, 0, 8)
notifTitle.BackgroundTransparency = 1
notifTitle.Font = Enum.Font.GothamBold
notifTitle.TextSize = 18
notifTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
notifTitle.TextXAlignment = Enum.TextXAlignment.Left
notifTitle.Parent = notifFrame

local notifDesc = Instance.new("TextLabel")
notifDesc.Name = "Description"
notifDesc.Size = UDim2.new(1, -20, 0, 70)
notifDesc.Position = UDim2.new(0, 10, 0, 38)
notifDesc.BackgroundTransparency = 1
notifDesc.Font = Enum.Font.Gotham
notifDesc.TextSize = 14
notifDesc.TextColor3 = Color3.fromRGB(220, 220, 230)
notifDesc.TextWrapped = true
notifDesc.TextXAlignment = Enum.TextXAlignment.Left
notifDesc.TextYAlignment = Enum.TextYAlignment.Top
notifDesc.Parent = notifFrame

local notifTween = nil
local function showNotification(title, desc)
	notifTitle.Text = title
	notifDesc.Text = desc
	notifFrame.Visible = true
	notifFrame.BackgroundTransparency = 0.1

	if notifTween then
		notifTween:Cancel()
	end

	task.delay(5, function()
		notifTween = TweenService:Create(notifFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		notifTween:Play()
		notifTween.Completed:Connect(function()
		notifFrame.Visible = false
		end)
	end)
end

-- Evidence collection tracking
local collectedEvidence = {}
local evidenceCount = 0

-- Evidence counter label
local evidenceLabel = Instance.new("TextLabel")
evidenceLabel.Name = "EvidenceCounter"
evidenceLabel.Size = UDim2.new(0, 200, 0, 30)
evidenceLabel.Position = UDim2.new(0, 10, 0, 10)
evidenceLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
evidenceLabel.BackgroundTransparency = 0.2
evidenceLabel.Font = Enum.Font.GothamBold
evidenceLabel.TextSize = 14
evidenceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
evidenceLabel.Text = "Evidence: 0"
evidenceLabel.Parent = screenGui

local evCorner = Instance.new("UICorner")
evCorner.CornerRadius = UDim.new(0, 6)
evCorner.Parent = evidenceLabel

-- CCTV Monitor UI
local cctvGui = Instance.new("Frame")
cctvGui.Name = "CCTVMonitor"
cctvGui.Size = UDim2.new(0, 600, 0, 450)
cctvGui.Position = UDim2.new(0.5, -300, 0.5, -225)
cctvGui.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
cctvGui.BorderSizePixel = 2
cctvGui.BorderColor3 = Color3.fromRGB(60, 120, 200)
cctvGui.Visible = false
cctvGui.Parent = screenGui

local cctvCorner = Instance.new("UICorner")
cctvCorner.CornerRadius = UDim.new(0, 8)
cctvCorner.Parent = cctvGui

local cctvTitle = Instance.new("TextLabel")
cctvTitle.Size = UDim2.new(1, 0, 0, 40)
cctvTitle.BackgroundTransparency = 1
cctvTitle.Font = Enum.Font.GothamBold
cctvTitle.TextSize = 20
cctvTitle.TextColor3 = Color3.fromRGB(100, 180, 255)
cctvTitle.Text = "CCTV Monitoring System"
cctvTitle.Parent = cctvGui

local cctvClose = Instance.new("TextButton")
cctvClose.Size = UDim2.new(0, 30, 0, 30)
cctvClose.Position = UDim2.new(1, -35, 0, 5)
cctvClose.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cctvClose.Font = Enum.Font.GothamBold
cctvClose.TextSize = 16
cctvClose.TextColor3 = Color3.fromRGB(255, 255, 255)
cctvClose.Text = "X"
cctvClose.Parent = cctvGui

local cctvCorner2 = Instance.new("UICorner")
cctvCorner2.CornerRadius = UDim.new(0, 6)
cctvCorner2.Parent = cctvClose

cctvClose.MouseButton1Click:Connect(function()
	cctvGui.Visible = false
	local camera = workspace.CurrentCamera
	if previousCameraType then camera.CameraType = previousCameraType end
	if previousCameraSubject then camera.CameraSubject = previousCameraSubject end
end)

local cctvList = Instance.new("ScrollingFrame")
cctvList.Size = UDim2.new(1, -20, 1, -60)
cctvList.Position = UDim2.new(0, 10, 0, 45)
cctvList.BackgroundTransparency = 1
cctvList.ScrollBarThickness = 4
cctvList.CanvasSize = UDim2.new(0, 0, 0, 0)
cctvList.AutomaticCanvasSize = Enum.AutomaticSize.Y
cctvList.Parent = cctvGui

local cctvLayout = Instance.new("UIListLayout")
cctvLayout.Padding = UDim.new(0, 8)
cctvLayout.Parent = cctvList

-- Handle CaseFileUpdated events
caseFileUpdatedRemote.OnClientEvent:Connect(function(data)
	if data.Type == "Evidence" then
		if not collectedEvidence[data.Id] then
			collectedEvidence[data.Id] = true
			evidenceCount = evidenceCount + 1
			evidenceLabel.Text = "Evidence: " .. evidenceCount
		end
		local suspects = data.Suspects and (" Possible: " .. table.concat(data.Suspects, ", ")) or ""
		showNotification("[EVIDENCE] " .. data.Title, data.Description .. " (Reliability: " .. (data.Reliability or "Unknown") .. ")." .. suspects)
	elseif data.Type == "AlreadyCollected" then
		showNotification(data.Title, data.Description)
	elseif data.Type == "Info" then
		showNotification(data.Title, data.Description)
	elseif data.Type == "Purchase" then
		showNotification(data.Title, data.Description)
	end
end)

-- Handle CCTV Monitor events
cctvMonitorRemote.OnClientEvent:Connect(function(cameras, online)
	-- Clear previous list
	for _, child in ipairs(cctvList:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if online == false then
		cctvTitle.Text = "CCTV Monitoring System — OFFLINE"
		cctvGui.Visible = true
		showNotification("CCTV System", "Camera feeds are disabled during the night.")
		return
	end
	cctvTitle.Text = "CCTV Monitoring System"
	-- Populate camera list
	for _, cam in ipairs(cameras) do
		local camFrame = Instance.new("TextButton")
		camFrame.Size = UDim2.new(1, -10, 0, 60)
		camFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
		camFrame.BackgroundTransparency = 0.2
		camFrame.Text = ""
		camFrame.Parent = cctvList

		local camCorner = Instance.new("UICorner")
		camCorner.CornerRadius = UDim.new(0, 6)
		camCorner.Parent = camFrame

		local camLabel = Instance.new("TextLabel")
		camLabel.Size = UDim2.new(1, -20, 1, 0)
		camLabel.Position = UDim2.new(0, 10, 0, 0)
		camLabel.BackgroundTransparency = 1
		camLabel.Font = Enum.Font.Gotham
		camLabel.TextSize = 14
		camLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
		camLabel.TextXAlignment = Enum.TextXAlignment.Left
		camLabel.Text = "[" .. cam.CameraId .. "] " .. cam.Location
		camLabel.Parent = camFrame

		local statusDot = Instance.new("Frame")
		statusDot.Size = UDim2.new(0, 10, 0, 10)
		statusDot.Position = UDim2.new(1, -20, 0.5, -5)
		statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		statusDot.Parent = camFrame

		camFrame.Activated:Connect(function()
			if not cam.CFrame then return end
			local camera = workspace.CurrentCamera
			previousCameraType = previousCameraType or camera.CameraType
			previousCameraSubject = previousCameraSubject or camera.CameraSubject
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = cam.CFrame
		end)

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = statusDot
	end

	cctvGui.Visible = true
	showNotification("CCTV System", "Accessed " .. #cameras .. " camera feeds. Evidence has been added to your case file.")
end)

-- Handle Cell State Change events
cellStateRemote.OnClientEvent:Connect(function(cellNumber, isOpen)
	local stateText = isOpen and "OPENED" or "CLOSED"
	showNotification("Holding Cell " .. (cellNumber + 1), "Cell door " .. stateText)
end)
