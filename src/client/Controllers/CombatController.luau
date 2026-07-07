--!strict
-- Translates a mouse click into the (payload-less) attack signal. No
-- damage/target logic lives on the client at all — the server decides
-- everything in CombatService.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local CombatController = {}

function CombatController.Init()
	local requestAttack = Remotes.GetEvent(NetConstants.RequestAttack)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessedEvent: boolean)
		if gameProcessedEvent then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			requestAttack:FireServer()
		end
	end)
end

return CombatController
