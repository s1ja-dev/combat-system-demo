--!strict
-- Shared color palette for the "chunky candy" UI style (thick outlines,
-- saturated gradient buttons, bold outlined fonts) — kept visually consistent
-- across every demo in this portfolio. One place to retune the whole game's
-- look.

local Theme = {
	Success = Color3.fromRGB(76, 209, 105), -- heal/positive actions
	Info = Color3.fromRGB(66, 150, 240), -- general actions
	Premium = Color3.fromRGB(178, 102, 255), -- rare/prestige accents
	Warning = Color3.fromRGB(255, 175, 64), -- rewards/attention
	Danger = Color3.fromRGB(235, 70, 70), -- close/damage/penalty
	Shop = Color3.fromRGB(64, 130, 220),

	PanelBackground = Color3.fromRGB(255, 255, 255),
	PanelStroke = Color3.fromRGB(20, 20, 25),
	ChipBackground = Color3.fromRGB(35, 38, 48),
	TextDark = Color3.fromRGB(35, 35, 40),
	TextLight = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(175, 178, 190),

	-- Three distinct built-in Roblox display fonts for combat callouts — no
	-- asset upload needed. Kept visually distinct from each other (and from
	-- GothamBold/GothamBlack body text) on purpose: a player should be able
	-- to tell "regular hit" / "headshot" / "kill" apart by silhouette alone.
	HitFont = Enum.Font.GothamBlack,
	HeadshotFont = Enum.Font.Bangers,
	KillFeedFont = Enum.Font.PermanentMarker,

	-- Bright, saturated yellow for headshot damage numbers — deliberately
	-- louder than Warning (used elsewhere for generic rewards/attention) so
	-- a headshot reads as its own, more urgent event.
	HeadshotYellow = Color3.fromRGB(255, 221, 0),
	-- Slightly dimmed white for regular hit damage numbers — still reads as
	-- "white" but sits back visually next to HeadshotYellow.
	HitWhite = Color3.fromRGB(232, 232, 232),
}

-- Darkens a color for outlines, mirroring the "stroke = darker shade of
-- fill" relationship seen in reference UI kits.
function Theme.Darken(color: Color3, factor: number): Color3
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.min(s * 1.1, 1), v * factor)
end

return Theme
