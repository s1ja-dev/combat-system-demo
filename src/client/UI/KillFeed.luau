--!strict
-- Scrolling "X eliminated Y" feed, headshots called out distinctly. Purely
-- cosmetic, listens to the broadcast CombatHit remote.

local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local IconAssets = require(ReplicatedStorage.Shared.Config.IconAssets)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)

local KillFeed = {}

local MAX_ENTRIES = 5
local ENTRY_LIFETIME = 4
local ENTRY_HEIGHT = 32
local ENTRY_WIDTH = 320
local TEXT_SIZE = 20
local ICON_SIZE = 18
local PAD = 10
local GAP = 6

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
	list.Size = UDim2.fromOffset(ENTRY_WIDTH, 220)
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

	-- Fixed-position layout (no AutomaticSize/UIListLayout on the entry
	-- itself — that combination silently failed to render at all when
	-- tried, root cause never pinned down) — text width is measured up
	-- front via TextService so the icon can still sit exactly between the
	-- "attacker verb" text and the target's name.
	local function addText(parent: Frame, text: string, x: number, width: number): TextLabel
		local seg = Instance.new("TextLabel")
		seg.Position = UDim2.fromOffset(x, 0)
		seg.Size = UDim2.fromOffset(width, ENTRY_HEIGHT)
		seg.BackgroundTransparency = 1
		seg.Text = text
		seg.TextColor3 = Theme.TextLight
		seg.TextStrokeColor3 = Color3.new(0, 0, 0)
		seg.TextStrokeTransparency = 0.4
		seg.Font = Theme.KillFeedFont
		seg.TextSize = TEXT_SIZE
		seg.TextXAlignment = Enum.TextXAlignment.Left
		seg.Parent = parent
		return seg
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
		entry.Size = UDim2.fromOffset(ENTRY_WIDTH, ENTRY_HEIGHT)
		-- Headshot kills turn the whole card red instead of just the text —
		-- reads as its own event at a glance, not just a colored word.
		entry.BackgroundColor3 = if data.WasHeadshot then Theme.Danger else Theme.ChipBackground
		entry.BackgroundTransparency = 0.15
		entry.BorderSizePixel = 0
		entry.Parent = list
		table.insert(entries, entry)

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = entry

		local iconId = IconAssets.Skull or ""
		if data.WasHeadshot and IconAssets.HeadshotKill and IconAssets.HeadshotKill ~= "" then
			iconId = IconAssets.HeadshotKill
		end

		local verb = if data.WasHeadshot then "HEADSHOT" else "eliminated"
		local verbText = `{data.AttackerName} {verb}`
		local verbWidth = TextService:GetTextSize(verbText, TEXT_SIZE, Theme.KillFeedFont, Vector2.new(1000, ENTRY_HEIGHT)).X
		addText(entry, verbText, PAD, verbWidth)

		local nextX = PAD + verbWidth + GAP
		if iconId ~= "" then
			local icon = Instance.new("ImageLabel")
			icon.Position = UDim2.fromOffset(nextX, (ENTRY_HEIGHT - ICON_SIZE) / 2)
			icon.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
			icon.BackgroundTransparency = 1
			icon.Image = iconId
			icon.Parent = entry
			nextX += ICON_SIZE + GAP
		end

		local targetWidth = TextService:GetTextSize(data.TargetName, TEXT_SIZE, Theme.KillFeedFont, Vector2.new(1000, ENTRY_HEIGHT)).X
		addText(entry, data.TargetName, nextX, targetWidth)
		-- Card hugs its actual content instead of always being ENTRY_WIDTH
		-- wide — a short name like "Noob" no longer leaves a block of empty
		-- colored space after it.
		entry.Size = UDim2.fromOffset(nextX + targetWidth + PAD, ENTRY_HEIGHT)

		task.delay(ENTRY_LIFETIME, function()
			if entry.Parent then
				TweenService:Create(entry, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
				for _, child in entry:GetChildren() do
					if child:IsA("TextLabel") then
						TweenService:Create(child, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
					elseif child:IsA("ImageLabel") then
						TweenService:Create(child, TweenInfo.new(0.4), { ImageTransparency = 1 }):Play()
					end
				end
				task.wait(0.4)
				removeEntry(entry)
			end
		end)
	end)
end

return KillFeed
