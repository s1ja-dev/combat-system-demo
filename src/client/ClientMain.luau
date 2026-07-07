--!strict
local Players = game:GetService("Players")

local CombatController = require(script.Parent.Controllers.CombatController)
local HealthBar = require(script.Parent.UI.HealthBar)
local KillFeed = require(script.Parent.UI.KillFeed)

local ClientMain = {}

function ClientMain.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	HealthBar.Init(screenGui)
	KillFeed.Init(screenGui)
	CombatController.Init()
end

return ClientMain
