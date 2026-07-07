--!strict
-- String identifiers for every remote. Kept separate from Remotes.luau so
-- both server and client can reference names without pulling in the
-- Instance-creation logic.

local NetConstants = {
	-- No payload at all: the server decides who got hit, at what range, and
	-- whether it was a headshot. The client only signals "I attacked now".
	RequestAttack = "RequestAttack",

	-- Broadcast to everyone for kill-feed + hit VFX/sound.
	CombatHit = "CombatHit",

	-- Sent only to the player whose health changed (their own health bar).
	HealthChanged = "HealthChanged",
}

return NetConstants
