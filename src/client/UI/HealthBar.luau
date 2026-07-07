--!strict
-- Local player's own health bar. Plain Frame+UICorner bar (no external
-- image assets needed), color shifts green -> orange -> red as health drops.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)

local HealthBar = {}

function HealthBar.Init(screenGui: ScreenGui)
	local track = Instance.new("Frame")
	track.Name = "HealthBarTrack"
	track.AnchorPoint = Vector2.new(0.5, 1)
	track.Position = UDim2.new(0.5, 0, 1, -24)
	track.Size = UDim2.fromOffset(280, 28)
	track.BackgroundColor3 = Theme.ChipBackground
	track.BorderSizePixel = 0
	track.Parent = screenGui

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 10)
	trackCorner.Parent = track

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Thickness = 3
	trackStroke.Color = Theme.Darken(Theme.ChipBackground, 0.5)
	trackStroke.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Theme.Success
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 10)
	fillCorner.Parent = fill

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "100 / 100"
	label.TextColor3 = Theme.TextLight
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.4
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.ZIndex = 2
	label.Parent = track

	local healthChanged = Remotes.GetEvent(NetConstants.HealthChanged)
	healthChanged.OnClientEvent:Connect(function(data: { Health: number, MaxHealth: number })
		local ratio = math.clamp(data.Health / data.MaxHealth, 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		fill.BackgroundColor3 = if ratio > 0.5
			then Theme.Success
			elseif ratio > 0.25 then Theme.Warning
			else Theme.Danger
		label.Text = `{math.max(math.floor(data.Health), 0)} / {math.floor(data.MaxHealth)}`
	end)
end

return HealthBar
