--!strict
-- String identifiers for every remote. Kept separate from Remotes.luau so
-- both server and client can reference names without pulling in the
-- Instance-creation logic.

local NetConstants = {
	-- No payload at all: the server decides who got hit, at what range, and
	-- whether it was a headshot. The client only signals "I attacked now".
	RequestAttack = "RequestAttack",

	-- Broadcast to everyone for kill-feed + hit VFX/sound. Payload includes
	-- HitPosition (world point, for VFX/damage-number placement) and Weapon
	-- ("Melee" | "Blaster") from both CombatService and WeaponService.
	CombatHit = "CombatHit",

	-- Sent only to the player whose health changed (their own health bar).
	HealthChanged = "HealthChanged",

	-- C->S {Origin: Vector3, Direction: Vector3} — the blaster's aim intent.
	-- Unlike RequestAttack this DOES carry a payload: a raycast weapon needs
	-- the client's aim direction, which the server has no other way to know.
	-- See WeaponService for how that trust is bounded.
	RequestFire = "RequestFire",

	-- Broadcast to everyone so other clients can render a shot's tracer even
	-- when it didn't land on anything.
	WeaponFired = "WeaponFired",
}

return NetConstants
