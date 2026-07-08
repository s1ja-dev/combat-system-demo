--!strict
-- Blaster input + local visual feedback. Only ever sends aim intent
-- (Origin/Direction) — the server independently raycasts, clamps range, and
-- decides all damage (see WeaponService). The tracer/muzzle SFX here are
-- pure cosmetics for instant local feedback; the authoritative hit (and
-- everyone else's kill-feed/VFX) comes back through the broadcast CombatHit
-- event, handled by VfxController/DamageNumbers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local SfxAssets = require(ReplicatedStorage.Shared.Config.SfxAssets)

local WeaponController = {}

local function playSfx(soundId: string, parent: Instance, volume: number)
	if soundId == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = parent
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function drawTracer(origin: Vector3, endPoint: Vector3)
	local offset = endPoint - origin
	local distance = offset.Magnitude
	if distance < 0.05 then
		return
	end

	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CastShadow = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(120, 220, 255)
	beam.Size = Vector3.new(0.08, 0.08, distance)
	beam.CFrame = CFrame.lookAt(origin, endPoint) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = Workspace
	Debris:AddItem(beam, 0.12)
end

function WeaponController.Init()
	local player = Players.LocalPlayer
	local mouse = player:GetMouse()
	local requestFire = Remotes.GetEvent(NetConstants.RequestFire)
	local weaponFired = Remotes.GetEvent(NetConstants.WeaponFired)

	local function fire(tool: Tool)
		local character = player.Character
		local handle = tool:FindFirstChild("Handle") :: BasePart?
		if not character or not handle then
			return
		end
		-- Recursive lookup: the primitive placeholder nests Muzzle under a
		-- separate "Barrel" part, but the real mesh (WeaponModel.buildFromMesh)
		-- has no such part and hangs Muzzle straight off Handle instead.
		local muzzle = tool:FindFirstChild("Muzzle", true) :: Attachment?

		local origin = if muzzle then muzzle.WorldPosition else handle.Position
		local targetPoint = if mouse.Hit
			then mouse.Hit.Position
			else origin + character:GetPivot().LookVector * WeaponConfig.Range
		local direction = targetPoint - origin
		if direction.Magnitude < 0.001 then
			return
		end
		direction = direction.Unit

		requestFire:FireServer({ Origin = origin, Direction = direction })

		drawTracer(origin, targetPoint)
		playSfx(SfxAssets.BlasterShot, handle, 0.6)
	end

	local function hookTool(tool: Instance)
		if not (tool:IsA("Tool") and tool.Name == WeaponConfig.ToolName) then
			return
		end
		tool.Activated:Connect(function()
			fire(tool)
		end)
	end

	local backpack = player:WaitForChild("Backpack")
	for _, child in backpack:GetChildren() do
		hookTool(child)
	end
	backpack.ChildAdded:Connect(hookTool)

	local function hookCharacter(character: Model)
		for _, child in character:GetChildren() do
			hookTool(child)
		end
		character.ChildAdded:Connect(hookTool)
	end
	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	-- Other players' shots: draw their tracer too, purely cosmetic. Our own
	-- shot already drew instantly above, so skip re-drawing it here.
	weaponFired.OnClientEvent:Connect(function(data: { Shooter: string, Origin: Vector3, Direction: Vector3 })
		if data.Shooter == player.Name then
			return
		end
		if typeof(data.Origin) ~= "Vector3" or typeof(data.Direction) ~= "Vector3" then
			return
		end
		drawTracer(data.Origin, data.Origin + data.Direction * WeaponConfig.Range)
	end)
end

return WeaponController
