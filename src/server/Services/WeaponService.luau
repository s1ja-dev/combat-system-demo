--!strict
-- Server-authoritative hitscan blaster. Unlike melee (RequestAttack carries
-- NO payload at all), a raycast weapon fundamentally needs the client's aim
-- direction — the server has no other way to know where a client's camera is
-- pointed. The trade-off is made explicit and bounded: the server clamps the
-- ray to WeaponConfig.Range regardless of what the client claims, and
-- rejects any Origin that isn't within WeaponConfig.MaxOriginSlack studs of
-- the attacker's actual HumanoidRootPart — a spoofed Origin planted next to a
-- distant target can't be used to snipe through walls from an impossible
-- spot. Headshot is decided by which exact part the raycast hit (no
-- proximity math needed, unlike melee).

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)

local WeaponModel = require(script.Parent.WeaponModel)
local HealthService = require(script.Parent.HealthService)
local DummyService = require(script.Parent.DummyService)

local WeaponService = {}

local nextFireAllowedAt: { [Player]: number } = {}

type Candidate = {
	Humanoid: Humanoid,
	DisplayName: string,
	ApplyDamage: (amount: number) -> boolean,
}

local function resolveCandidate(model: Model): Candidate?
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(model)
	if player then
		return {
			Humanoid = humanoid,
			DisplayName = player.Name,
			ApplyDamage = function(amount: number)
				return HealthService.ApplyDamage(player, amount)
			end,
		}
	end

	if CollectionService:HasTag(model, CombatConfig.DummyTag) then
		return {
			Humanoid = humanoid,
			DisplayName = model.Name,
			ApplyDamage = function(amount: number)
				return DummyService.ApplyDamage(model, amount)
			end,
		}
	end

	return nil
end

local function onRequestFire(attacker: Player, payload: unknown)
	if typeof(payload) ~= "table" then
		return
	end
	local data = payload :: { Origin: unknown, Direction: unknown }
	if typeof(data.Origin) ~= "Vector3" or typeof(data.Direction) ~= "Vector3" then
		return
	end
	local origin = data.Origin :: Vector3
	local direction = data.Direction :: Vector3

	local now = os.clock()
	if (nextFireAllowedAt[attacker] or 0) > now then
		return
	end
	nextFireAllowedAt[attacker] = now + WeaponConfig.FireCooldown

	local character = attacker.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not character or not root then
		return
	end

	if (origin - root.Position).Magnitude > WeaponConfig.MaxOriginSlack then
		return
	end

	if direction.Magnitude < 0.001 then
		return
	end
	direction = direction.Unit

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }

	local result = Workspace:Raycast(origin, direction * WeaponConfig.Range, params)

	local weaponFired = Remotes.GetEvent(NetConstants.WeaponFired)
	weaponFired:FireAllClients({ Shooter = attacker.Name, Origin = origin, Direction = direction })

	if not result then
		return
	end

	local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
	if not hitModel then
		return
	end

	local candidate = resolveCandidate(hitModel)
	if not candidate then
		return
	end

	local headshot = result.Instance.Name == "Head"
	local damage = WeaponConfig.BaseDamage * (if headshot then WeaponConfig.HeadshotMultiplier else 1)

	local hitLanded = candidate.ApplyDamage(damage)
	if not hitLanded then
		return
	end

	local combatHit = Remotes.GetEvent(NetConstants.CombatHit)
	combatHit:FireAllClients({
		AttackerName = attacker.Name,
		TargetName = candidate.DisplayName,
		Damage = damage,
		WasHeadshot = headshot,
		TargetDied = candidate.Humanoid.Health <= 0,
		HitPosition = result.Position,
		Weapon = "Blaster",
	})
end

local function ensureWeapon(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and not backpack:FindFirstChild(WeaponConfig.ToolName) then
		WeaponModel.Build().Parent = backpack
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function()
		ensureWeapon(player)
	end)
	if player.Character then
		ensureWeapon(player)
	end
end

function WeaponService.Init()
	Players.PlayerRemoving:Connect(function(player: Player)
		nextFireAllowedAt[player] = nil
	end)

	local requestFire = Remotes.GetEvent(NetConstants.RequestFire)
	requestFire.OnServerEvent:Connect(onRequestFire)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return WeaponService
