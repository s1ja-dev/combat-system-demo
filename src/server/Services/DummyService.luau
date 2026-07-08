--!strict
-- Server-owned lifecycle for combat training dummies: plain Humanoid rigs
-- tagged "CombatDummy" in Workspace (see CombatConfig.DummyTag). A dummy has
-- no Player behind it, so there's no LoadCharacter-based respawn — but a
-- Humanoid that has actually entered the Dead state (Health hit 0 and Died
-- fired) can't be revived by setting Health back up either: Roblox snaps it
-- straight back to 0 the instant you try. The reliable fix, same as a
-- Player's LoadCharacter, is to destroy the corpse and parent in a fresh
-- clone instead of reviving in place.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)

local RagdollService = require(script.Parent.RagdollService)

local DummyService = {}

local invulnerableUntil: { [Model]: number } = {}

local function setupDummy(model: Instance)
	if not model:IsA("Model") then
		return
	end

	-- Guards against being wired up twice: this runs both from the initial
	-- GetTagged scan and CollectionService's InstanceAdded signal, and a
	-- respawned clone re-enters the tagged set the same way a freshly
	-- authored dummy would.
	if model:GetAttribute("_DummySetupDone") then
		return
	end
	model:SetAttribute("_DummySetupDone", true)

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.MaxHealth = CombatConfig.MaxHealth
	humanoid.Health = CombatConfig.MaxHealth
	-- Roblox's own built-in floating health bar — zero custom GUI needed for
	-- every client to see the dummy's health change in real time.
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.BreakJointsOnDeath = false

	humanoid.Died:Connect(function()
		-- Snapshot a pristine clone BEFORE ragdolling — RagdollService mutates
		-- `model` in place (disables Motor6Ds, adds constraints), and cloning
		-- from an already-ragdolled corpse would carry that broken rig into
		-- the respawn. Taking the clone first guarantees it's identical to
		-- the dummy's original, working state.
		local respawnTemplate = model:Clone()
		RagdollService.Ragdoll(model)

		task.delay(CombatConfig.RespawnTime, function()
			local parent = model.Parent
			local pivot = model:GetPivot()
			invulnerableUntil[model] = nil

			if not parent then
				-- Someone removed it from Workspace entirely; don't respawn.
				respawnTemplate:Destroy()
				return
			end

			local fresh = respawnTemplate
			fresh:SetAttribute("_DummySetupDone", nil)

			-- Reset Health while still off-tree, before Roblox's Humanoid
			-- state machine starts simulating it — doing this after
			-- parenting risks the same "was already dead" snap-back.
			local freshHumanoid = fresh:FindFirstChildOfClass("Humanoid")
			if freshHumanoid then
				freshHumanoid.Health = freshHumanoid.MaxHealth
			end

			fresh:PivotTo(pivot)
			fresh.Parent = parent
			invulnerableUntil[fresh] = os.clock() + CombatConfig.InvulnerabilityDuration
			setupDummy(fresh)

			model:Destroy()
		end)
	end)
end

function DummyService.IsInvulnerable(model: Model): boolean
	local until_ = invulnerableUntil[model]
	return until_ ~= nil and os.clock() < until_
end

-- Mirrors HealthService.ApplyDamage's shape (returns whether the hit
-- actually landed) so CombatService can treat both uniformly.
function DummyService.ApplyDamage(model: Model, amount: number): boolean
	if DummyService.IsInvulnerable(model) then
		return false
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	humanoid:TakeDamage(amount)
	return true
end

function DummyService.Init()
	for _, model in CollectionService:GetTagged(CombatConfig.DummyTag) do
		setupDummy(model)
	end
	CollectionService:GetInstanceAddedSignal(CombatConfig.DummyTag):Connect(setupDummy)
end

return DummyService
