--!strict
-- Spawns the KitsBlox particle-hit VFX (shared/Assets/VFX) at the point of
-- impact reported by the server, and plays the matching hit sound. Melee
-- hits use the "MeleeHit" template, blaster hits use "BlasterHit" — picked
-- purely from the Weapon field the server already includes in every
-- CombatHit broadcast. Pure client-side cosmetics; nothing here can affect
-- damage or who won a fight.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local SfxAssets = require(ReplicatedStorage.Shared.Config.SfxAssets)

local VfxController = {}

local VFX_LIFETIME = 3

local function emit(template: BasePart, position: Vector3)
	local clone = template:Clone()
	clone.Anchored = true
	clone.CanCollide = false
	clone.Transparency = 1
	clone.Position = position
	clone.Parent = Workspace

	local attachment = clone:FindFirstChildWhichIsA("Attachment")
	if attachment then
		for _, emitter in attachment:GetChildren() do
			if emitter:IsA("ParticleEmitter") then
				local count = emitter:GetAttribute("EmitCount")
				emitter:Emit(if typeof(count) == "number" then count else 16)
			end
		end
	end

	Debris:AddItem(clone, VFX_LIFETIME)
end

local function playSfx(soundId: string, position: Vector3)
	if soundId == "" then
		return
	end

	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Position = position
	anchor.Parent = Workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = anchor
	sound:Play()

	Debris:AddItem(anchor, 3)
end

type HitData = {
	WasHeadshot: boolean,
	HitPosition: Vector3?,
	Weapon: string?,
}

function VfxController.Init()
	local vfxFolder = ReplicatedStorage.Shared.Assets.VFX
	local meleeTemplate = vfxFolder:FindFirstChild("MeleeHit") :: BasePart?
	local blasterTemplate = vfxFolder:FindFirstChild("BlasterHit") :: BasePart?

	local combatHit = Remotes.GetEvent(NetConstants.CombatHit)
	combatHit.OnClientEvent:Connect(function(data: HitData)
		local hitPosition = data.HitPosition
		if typeof(hitPosition) ~= "Vector3" then
			return
		end

		local template = if data.Weapon == "Blaster" then blasterTemplate else meleeTemplate
		if template then
			emit(template, hitPosition)
		end

		-- Weapon decides the sound family first, headshot only picks a
		-- variant within melee: a ranged hitmarker is right for every
		-- blaster hit (body or head), so it never falls through to the
		-- melee punch sound the way a naive "headshot first" check would.
		local sfxId
		if data.Weapon == "Blaster" then
			sfxId = SfxAssets.BlasterHit
		elseif data.WasHeadshot then
			sfxId = SfxAssets.MeleeHeadshotHit
		else
			sfxId = SfxAssets.MeleeHit
		end
		playSfx(sfxId, hitPosition)
	end)
end

return VfxController
