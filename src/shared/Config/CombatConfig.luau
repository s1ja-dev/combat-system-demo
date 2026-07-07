--!strict
-- All tunable combat numbers in one place — no magic numbers in the service
-- logic itself.

local CombatConfig = {
	MaxHealth = 100,

	-- Attacker must be facing roughly toward the target (dot product of
	-- attacker's look vector and the direction to target) to land a hit —
	-- prevents "attack anyone anywhere behind you" exploitation.
	MaxAttackRange = 10,
	MinFacingDot = 0.4,
	AttackCooldown = 0.6,

	BaseDamage = 18,
	HeadshotMultiplier = 2,
	-- Distance (studs) between the ATTACKER's Head and the TARGET's Head
	-- (not attacker-root-to-target-head — see CombatService.isHeadshot for
	-- why that comparison doesn't work) within which a hit counts as a
	-- headshot instead of a body hit.
	HeadshotRadius = 3,

	RespawnTime = 3,
	InvulnerabilityDuration = 1.5,

	-- CollectionService tag marking a Workspace Model as a valid combat
	-- target even though it isn't a real Player (a training dummy rig).
	DummyTag = "CombatDummy",
}

return CombatConfig
