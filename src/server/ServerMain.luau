--!strict
-- Orchestrates service initialization order and the shared Remotes-folder
-- bootstrap. This is the only module that knows about every service.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetConstants = require(ReplicatedStorage.Shared.Net.NetConstants)
local Remotes = require(ReplicatedStorage.Shared.Net.Remotes)

local HealthService = require(script.Parent.Services.HealthService)
local DummyService = require(script.Parent.Services.DummyService)
local CombatService = require(script.Parent.Services.CombatService)

local ServerMain = {}

function ServerMain.Start()
	-- Touching any remote up front forces the whole Remotes folder to be
	-- created before any service could otherwise race to create it lazily.
	Remotes.GetEvent(NetConstants.RequestAttack)

	HealthService.Init()
	DummyService.Init()
	CombatService.Init()
end

return ServerMain
