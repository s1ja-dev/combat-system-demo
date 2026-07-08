--!strict
-- Icon image ids for combat UI. Uploaded via the Roblox Open Cloud Assets
-- API from Desktop/RobloxDev Files/UI/Game-Icon-Pack-v1.4-PNG/ (2026-07-08).
-- Every consumer only sets an Image if the id is non-empty, so an empty
-- string here would just fall back to the current text/color placeholder.
--
-- IMPORTANT: uploading with assetType="Decal" returns a Decal *wrapper*
-- asset id — that id does NOT work directly as an ImageLabel.Image source.
-- The actual usable image id is the wrapper's own .Texture property,
-- fetched once via game:GetObjects("rbxassetid://<wrapper id>") in Studio
-- (Plugin-capability only, same restriction as the mesh loading — see
-- WeaponModel.luau). The ids below are already the resolved Texture ids,
-- not the raw upload ids.
local IconAssets = {
	-- .../padding/128px/white/1-game/heart.png (wrapper id 77700355277991)
	Health = "rbxassetid://78043789580301",
	-- .../padding/128px/white/3-gear/pistol.png (wrapper id 84341904871468)
	Weapon = "rbxassetid://112847246459842",
	-- .../padding/128px/white/1-game/skull.png (wrapper id 114048018741333)
	Skull = "rbxassetid://73207340486373",
	-- .../padding/128px/white/6-buildings/target.png (wrapper id 85308554441454)
	Headshot = "rbxassetid://75673102527821",
	-- .../no-padding/64px/black/1-game/death.png (wrapper id 77923694959469)
	-- — kill-feed icon specifically for headshot kills.
	HeadshotKill = "rbxassetid://122123701730663",
}

return IconAssets
