--!strict
local Players = game:GetService("Players")

local CombatController = require(script.Parent.Controllers.CombatController)
local WeaponController = require(script.Parent.Controllers.WeaponController)
local VfxController = require(script.Parent.Controllers.VfxController)
local HealthBar = require(script.Parent.UI.HealthBar)
local KillFeed = require(script.Parent.UI.KillFeed)
local DamageNumbers = require(script.Parent.UI.DamageNumbers)

local ClientMain = {}

function ClientMain.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CombatUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	HealthBar.Init(screenGui)
	KillFeed.Init(screenGui)
	DamageNumbers.Init()
	CombatController.Init()
	WeaponController.Init()
	VfxController.Init()
end

return ClientMain
