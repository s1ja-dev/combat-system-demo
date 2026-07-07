--!strict
-- Scrolling "X eliminated Y" feed, headshots called out distinctly. Purely
-- cosmetic, listens to the broadcast CombatHit remote.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)

local KillFeed = {}

local MAX_ENTRIES = 5
local ENTRY_LIFETIME = 4

type HitData = {
	AttackerName: string,
	TargetName: string,
	Damage: number,
	WasHeadshot: boolean,
	TargetDied: boolean,
}

function KillFeed.Init(screenGui: ScreenGui)
	local list = Instance.new("Frame")
	list.Name = "KillFeed"
	list.AnchorPoint = Vector2.new(1, 0)
	list.Position = UDim2.new(1, -16, 0, 16)
	list.Size = UDim2.fromOffset(320, 220)
	list.BackgroundTransparency = 1
	list.Parent = screenGui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = list

	local entries: { Frame } = {}

	local function removeEntry(entry: Frame)
		local index = table.find(entries, entry)
		if index then
			table.remove(entries, index)
		end
		entry:Destroy()
	end

	local combatHit = Remotes.GetEvent(NetConstants.CombatHit)
	combatHit.OnClientEvent:Connect(function(data: HitData)
		if not data.TargetDied then
			return
		end

		if #entries >= MAX_ENTRIES then
			local oldest = table.remove(entries, 1)
			if oldest then
				oldest:Destroy()
			end
		end

		local entry = Instance.new("Frame")
		entry.Size = UDim2.fromOffset(320, 32)
		entry.BackgroundColor3 = Theme.ChipBackground
		entry.BackgroundTransparency = 0.15
		entry.BorderSizePixel = 0
		entry.Parent = list
		table.insert(entries, entry)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = entry

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = if data.WasHeadshot
			then `{data.AttackerName} ⚡ HEADSHOT ⚡ {data.TargetName}`
			else `{data.AttackerName} eliminated {data.TargetName}`
		label.TextColor3 = if data.WasHeadshot then Theme.Warning else Theme.TextLight
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Parent = entry

		task.delay(ENTRY_LIFETIME, function()
			if entry.Parent then
				TweenService:Create(entry, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
				TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
				task.wait(0.4)
				removeEntry(entry)
			end
		end)
	end)
end

return KillFeed
