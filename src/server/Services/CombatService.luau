--!strict
-- Server-authoritative melee combat. `RequestAttack` carries NO payload at
-- all — the client never tells the server who it hit or how hard. The
-- server independently finds the nearest valid target in front of the
-- attacker (range + facing-cone check), decides whether it's a headshot by
-- proximity to the target's own Head part, and applies damage from
-- CombatConfig. This closes off an entire class of exploit ("attack anyone
-- from anywhere") that a client-supplied target/damage payload would open.
--
-- Targets are either a real Player's character or a Workspace Model tagged
-- CombatConfig.DummyTag (a training dummy — see DummyService) — both are
-- reduced to the same small "candidate" shape below so the range/facing/
-- headshot math is written exactly once regardless of which kind it is.

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local CombatConfig = require(ReplicatedStorage.Shared.Config.CombatConfig)

local HealthService = require(script.Parent.HealthService)
local DummyService = require(script.Parent.DummyService)

local CombatService = {}

local nextAttackAllowedAt: { [Player]: number } = {}

type Candidate = {
	RootPart: BasePart,
	Head: BasePart,
	Humanoid: Humanoid,
	DisplayName: string,
	ApplyDamage: (amount: number) -> boolean,
}

-- Common shape check for any Humanoid-driven Model, whether it's a Player's
-- Character or a standalone dummy rig.
local function getAliveParts(model: Model): (BasePart?, BasePart?, Humanoid?)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local head = model:FindFirstChild("Head") :: BasePart?
	if not humanoid or humanoid.Health <= 0 or not rootPart or not head then
		return nil, nil, nil
	end
	return rootPart, head, humanoid
end

local function attackerRootAndHead(attacker: Player): (BasePart?, BasePart?)
	local character = attacker.Character
	if not character then
		return nil, nil
	end
	local rootPart, head = getAliveParts(character)
	return rootPart, head
end

local function playerCandidate(player: Player): Candidate?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart, head, humanoid = getAliveParts(character)
	if not rootPart or not head or not humanoid then
		return nil
	end

	return {
		RootPart = rootPart,
		Head = head,
		Humanoid = humanoid,
		DisplayName = player.Name,
		ApplyDamage = function(amount: number)
			return HealthService.ApplyDamage(player, amount)
		end,
	}
end

local function dummyCandidate(model: Model): Candidate?
	local rootPart, head, humanoid = getAliveParts(model)
	if not rootPart or not head or not humanoid then
		return nil
	end

	return {
		RootPart = rootPart,
		Head = head,
		Humanoid = humanoid,
		DisplayName = model.Name,
		ApplyDamage = function(amount: number)
			return DummyService.ApplyDamage(model, amount)
		end,
	}
end

-- Finds the nearest valid candidate (other player or dummy) within range and
-- roughly in front of the attacker. Returns nil if nothing qualifies.
local function findTarget(attacker: Player, attackerRoot: BasePart): Candidate?
	local best: Candidate? = nil
	local bestDistance = math.huge

	local function consider(candidate: Candidate?)
		if not candidate then
			return
		end

		local offset = candidate.RootPart.Position - attackerRoot.Position
		local distance = offset.Magnitude
		if distance > CombatConfig.MaxAttackRange or distance <= 0 then
			return
		end

		local facingDot = attackerRoot.CFrame.LookVector:Dot(offset.Unit)
		if facingDot < CombatConfig.MinFacingDot then
			return
		end

		if distance < bestDistance then
			bestDistance = distance
			best = candidate
		end
	end

	for _, player in Players:GetPlayers() do
		if player ~= attacker then
			consider(playerCandidate(player))
		end
	end

	for _, model in CollectionService:GetTagged(CombatConfig.DummyTag) do
		if model:IsA("Model") then
			consider(dummyCandidate(model))
		end
	end

	return best
end

-- Compares the attacker's own Head to the target's Head — not the
-- attacker's root to the target's head. A standing rig's Head sits ~2 studs
-- above its own root, so root-to-head would carry that offset as a
-- permanent bias and could nearly never fall inside a tight radius. Two
-- standing characters (or a standing character and a standing dummy) have
-- their heads at almost the same height, so head-to-head distance reduces
-- to roughly the actual horizontal gap between them, which is what "landed
-- on the head" should mean.
local function isHeadshot(attackerHead: BasePart, target: Candidate): boolean
	return (target.Head.Position - attackerHead.Position).Magnitude <= CombatConfig.HeadshotRadius
end

local function onRequestAttack(attacker: Player)
	local now = os.clock()
	if (nextAttackAllowedAt[attacker] or 0) > now then
		return
	end
	nextAttackAllowedAt[attacker] = now + CombatConfig.AttackCooldown

	local attackerRoot, attackerHead = attackerRootAndHead(attacker)
	if not attackerRoot or not attackerHead then
		return
	end

	local target = findTarget(attacker, attackerRoot)
	if not target then
		return
	end

	local headshot = isHeadshot(attackerHead, target)
	local damage = CombatConfig.BaseDamage * (if headshot then CombatConfig.HeadshotMultiplier else 1)

	local hitLanded = target.ApplyDamage(damage)
	if not hitLanded then
		return
	end

	local combatHit = Remotes.GetEvent(NetConstants.CombatHit)
	combatHit:FireAllClients({
		AttackerName = attacker.Name,
		TargetName = target.DisplayName,
		Damage = damage,
		WasHeadshot = headshot,
		TargetDied = target.Humanoid.Health <= 0,
		HitPosition = target.Head.Position,
		Weapon = "Melee",
	})
end

function CombatService.Init()
	Players.PlayerRemoving:Connect(function(player: Player)
		nextAttackAllowedAt[player] = nil
	end)

	local requestAttack = Remotes.GetEvent(NetConstants.RequestAttack)
	requestAttack.OnServerEvent:Connect(onRequestAttack)
end

return CombatService
