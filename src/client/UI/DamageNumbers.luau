--!strict
-- Floating "-18" / "-28 HEADSHOT" damage text at the hit location. Pure
-- client-side cosmetic reacting to the broadcast CombatHit event — the
-- server never sends anything UI-specific, just the same numbers it already
-- computed for the kill feed.

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local ClientRoot = script.Parent.Parent
local Theme = require(ClientRoot.Theme)

local DamageNumbers = {}

type HitData = {
	Damage: number,
	WasHeadshot: boolean,
	HitPosition: Vector3?,
}

function DamageNumbers.Init()
	local combatHit = Remotes.GetEvent(NetConstants.CombatHit)
	combatHit.OnClientEvent:Connect(function(data: HitData)
		local hitPosition = data.HitPosition
		if typeof(hitPosition) ~= "Vector3" then
			return
		end

		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.1, 0.1, 0.1)
		anchor.CFrame = CFrame.new(hitPosition + Vector3.new(0, 1.5, 0))
		anchor.Parent = Workspace

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(160, 60)
		billboard.AlwaysOnTop = true
		billboard.Parent = anchor

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = if data.WasHeadshot then `-{math.floor(data.Damage)} HEADSHOT` else `-{math.floor(data.Damage)}`
		label.TextColor3 = if data.WasHeadshot then Theme.HeadshotYellow else Theme.HitWhite
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0.2
		label.Font = if data.WasHeadshot then Theme.HeadshotFont else Theme.HitFont
		label.TextScaled = true
		label.Parent = billboard

		TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = anchor.CFrame + Vector3.new(0, 3, 0),
		}):Play()
		TweenService:Create(label, TweenInfo.new(0.9), {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		}):Play()

		Debris:AddItem(anchor, 1)
	end)
end

return DamageNumbers
