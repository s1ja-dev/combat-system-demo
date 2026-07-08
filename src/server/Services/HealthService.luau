--!strict
-- Server-authoritative health: the server is the only thing that ever calls
-- Humanoid:TakeDamage. Handles max-health setup, per-player health broadcast
-- (only to the owning client, for their own health bar), and a respawn cycle
-- with a short invulnerability window so a fresh spawn can't be instantly
-- re-killed by a lingering attacker.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)

local RagdollService = require(script.Parent.RagdollService)

local HealthService = {}

local invulnerableUntil: { [Player]: number } = {}

local function setupCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.MaxHealth = CombatConfig.MaxHealth
	humanoid.Health = CombatConfig.MaxHealth
	-- Roblox's own built-in "break joints on death" would otherwise recreate
	-- fresh, fully-enabled Motor6Ds right after RagdollService disables them
	-- — confirmed live (BallSocketConstraints got created correctly but the
	-- Motor6Ds came back Enabled moments later). Disabling it here hands
	-- ragdoll duty entirely to RagdollService, with nothing competing.
	humanoid.BreakJointsOnDeath = false

	invulnerableUntil[player] = os.clock() + CombatConfig.InvulnerabilityDuration

	local healthChanged = Remotes.GetEvent(NetConstants.HealthChanged)
	humanoid.HealthChanged:Connect(function(health: number)
		healthChanged:FireClient(player, { Health = health, MaxHealth = humanoid.MaxHealth })
	end)
	healthChanged:FireClient(player, { Health = humanoid.Health, MaxHealth = humanoid.MaxHealth })

	humanoid.Died:Connect(function()
		invulnerableUntil[player] = nil
		RagdollService.Ragdoll(character)
		task.delay(CombatConfig.RespawnTime, function()
			if player.Parent then
				player:LoadCharacter()
			end
		end)
	end)
end

function HealthService.IsInvulnerable(player: Player): boolean
	local until_ = invulnerableUntil[player]
	return until_ ~= nil and os.clock() < until_
end

-- Returns true if the hit actually landed (target was alive and not
-- invulnerable) so CombatService knows whether to broadcast a hit event.
function HealthService.ApplyDamage(target: Player, amount: number): boolean
	if HealthService.IsInvulnerable(target) then
		return false
	end

	local character = target.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	humanoid:TakeDamage(amount)
	return true
end

function HealthService.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(character: Model)
			setupCharacter(player, character)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		invulnerableUntil[player] = nil
	end)
end

return HealthService
