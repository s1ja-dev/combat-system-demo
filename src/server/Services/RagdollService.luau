--!strict
-- Classic Motor6D -> BallSocketConstraint ragdoll swap. Works for both R6 and
-- R15 rigs without special-casing either, since it just walks every Motor6D
-- under the character and replaces it with a physically simulated ball-
-- socket joint at the exact same pivot. Called once, right when a Humanoid
-- actually dies (Player or CombatDummy) — the corpse is short-lived in both
-- cases (respawn/clone-replace already happens elsewhere), so nothing here
-- needs to be reversible.

local RagdollService = {}

function RagdollService.Ragdoll(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
	end

	for _, joint in character:GetDescendants() do
		if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
			local part0, part1 = joint.Part0, joint.Part1

			local attachment0 = Instance.new("Attachment")
			attachment0.CFrame = joint.C0
			attachment0.Parent = part0

			local attachment1 = Instance.new("Attachment")
			attachment1.CFrame = joint.C1
			attachment1.Parent = part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = attachment0
			socket.Attachment1 = attachment1
			socket.LimitsEnabled = true
			socket.TwistLimitsEnabled = true
			socket.Parent = part0

			joint.Enabled = false
		end
	end

	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = true
		end
	end
end

return RagdollService
