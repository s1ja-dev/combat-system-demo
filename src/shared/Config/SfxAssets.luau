--!strict
-- Sound ids for combat SFX. Uploaded via the Roblox Open Cloud Assets API
-- from Desktop/RobloxDev Files/SFX/ (2026-07-08). Every consumer
-- (WeaponController, VfxController) already checks for an empty string and
-- stays silent, so this degrades gracefully if a ref is ever cleared.
local SfxAssets = {
	-- Desktop/RobloxDev Files/SFX/SFX of blasters/universfield-sci-fi-blaster-shot-229313.mp3
	BlasterShot = "rbxassetid://139098400970419",
	-- Desktop/RobloxDev Files/SFX/hitmarker_2.mp3 — used for every blaster
	-- hit (body AND headshot); a punch sound never made sense for a ranged
	-- weapon, which is why MeleeHeadshotHit below is melee-only now.
	BlasterHit = "rbxassetid://85579084943019",
	-- Desktop/RobloxDev Files/SFX/SFX of punches/universfield-classic-punch-impact-352711.mp3
	MeleeHit = "rbxassetid://95941933444299",
	-- Desktop/RobloxDev Files/SFX/SFX of punches/universfield-power-punch-192118.mp3
	MeleeHeadshotHit = "rbxassetid://119903317005946",
}

return SfxAssets
