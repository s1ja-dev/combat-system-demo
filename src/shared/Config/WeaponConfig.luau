--!strict
-- Tunable numbers for the ranged blaster weapon. Kept separate from
-- CombatConfig (melee) since a raycast weapon has a different trust model —
-- see WeaponService for why.

local WeaponConfig = {
	ToolName = "Blaster",

	BaseDamage = 14,
	HeadshotMultiplier = 2,
	Range = 200,
	FireCooldown = 0.35,

	-- Max studs the client-claimed muzzle Origin may be from the attacker's
	-- actual HumanoidRootPart before the shot is rejected outright — blocks a
	-- spoofed Origin planted next to a distant target. The aim Direction
	-- itself still has to be trusted (the server has no other way to know
	-- where a client's camera is pointed for a ranged weapon).
	MaxOriginSlack = 8,
}

return WeaponConfig
