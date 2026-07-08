--!strict
-- Builds the blaster Tool. Primary path: clone the pre-built real Kenney
-- mesh template synced in from shared/Assets/BlasterMesh.rbxmx (a Tool with
-- Handle + magazine MeshParts, already scaled/welded/muzzle-attached).
--
-- That file was produced by a one-time manual step, not something this
-- codebase can (re)generate on its own: the mesh started as a raw FBX
-- (Desktop/RobloxDev Files/kenney_blaster-kit_2.1), got uploaded via the
-- Roblox Open Cloud Assets API, then pulled into Studio's Edit-mode
-- DataModel with game:GetObjects — which only works from Plugin-capability
-- contexts (confirmed live: a real Script gets "cannot call 'GetObjects'
-- (lacking capability Plugin)"). So this can't be done from a running game
-- at all, published or not — the mesh had to be scaled/assembled once in
-- Studio and exported to a static .rbxmx file for Rojo to track like any
-- other asset (see shared/Assets/VFX for the same pattern).
--
-- Falls back to a block-built placeholder if the template is ever missing,
-- rather than leaving players with a toolless Tool. WeaponService/
-- WeaponController never care which path built the Tool: both only ever
-- look up parts by name ("Handle", "Muzzle" — found via a recursive search,
-- not a fixed parent).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IconAssets = require(ReplicatedStorage.Shared.Config.IconAssets)

local WeaponModel = {}

local function applyToolMeta(tool: Tool)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	if IconAssets.Weapon ~= "" then
		tool.TextureId = IconAssets.Weapon
	end
end

local function buildFromMesh(): Tool?
	-- WaitForChild, not FindFirstChild: this can run on the very first frame
	-- of server boot (a player already in the game when the server starts).
	-- In live Rojo-synced testing, a brand-new play session has to push its
	-- entire tree over again from scratch, and a binary MeshPart asset can
	-- take over 10 real seconds to land after the scripts do (confirmed
	-- live: 6s wasn't enough, 18s was) — a published place has no such race
	-- at all, since its ReplicatedStorage content is baked into the file and
	-- available from frame one. The generous timeout only ever matters
	-- during Rojo-live testing.
	local assets = ReplicatedStorage.Shared:WaitForChild("Assets", 15)
	local template = assets and assets:WaitForChild("BlasterMesh", 15)
	if not template or not template:IsA("Tool") then
		return nil
	end

	local tool = template:Clone()
	tool.Name = "Blaster"
	applyToolMeta(tool)
	return tool
end

local function part(name: string, size: Vector3, color: Color3, cframe: CFrame): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.CFrame = cframe
	return p
end

local function buildFromPrimitives(): Tool
	local tool = Instance.new("Tool")
	tool.Name = "Blaster"
	applyToolMeta(tool)

	local handle = part("Handle", Vector3.new(0.6, 0.6, 2.2), Color3.fromRGB(60, 65, 75), CFrame.new())
	handle.Parent = tool

	local barrel = part("Barrel", Vector3.new(0.35, 0.35, 1.4), Color3.fromRGB(35, 38, 45), handle.CFrame * CFrame.new(0, 0.05, -1.6))
	barrel.Parent = tool

	local grip = part("Grip", Vector3.new(0.5, 1, 0.6), Color3.fromRGB(45, 48, 55), handle.CFrame * CFrame.new(0, -0.7, 0.6))
	grip.Parent = tool

	local sight = part("Sight", Vector3.new(0.15, 0.2, 0.4), Color3.fromRGB(20, 22, 26), handle.CFrame * CFrame.new(0, 0.4, -0.2))
	sight.Parent = tool

	for _, child in { barrel, grip, sight } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = child
		weld.Parent = handle
	end

	local muzzle = Instance.new("Attachment")
	muzzle.Name = "Muzzle"
	muzzle.CFrame = CFrame.new(0, 0.05, -0.75)
	muzzle.Parent = barrel

	return tool
end

function WeaponModel.Build(): Tool
	local ok, meshOrErr = pcall(buildFromMesh)
	if not ok then
		warn("[WeaponModel] buildFromMesh errored:", meshOrErr)
	end
	local mesh = if ok then meshOrErr else nil
	return mesh or buildFromPrimitives()
end

return WeaponModel
