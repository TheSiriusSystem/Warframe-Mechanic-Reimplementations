--!strict
local ServerStorage = game:GetService("ServerStorage")
local ActorBase = require(ServerStorage.Modules.ActorBase)

local actor: {[string]: any} = ActorBase.Actors[script.Parent]

return {
	Tags = {
		"Organic",
	},
	HideLevel = true,
	Health = {
		Base = 100.0,
		Class = "TennoFlesh",
		RegenAmount = function(deltaTime: number): number
			return (actor.humanoid.MaxHealth * 0.05) * deltaTime
		end,
	},
	Shield = {
		Base = 150.0,
		Class = "TennoShield",
		Impenetrable = false,
		RegenAmount = function(deltaTime: number): number
			return (15.0 + (actor.humanoid:GetAttribute("MaxShield") * 0.05)) * deltaTime
		end,
	},
	Armor = {
		Base = 105.0,
		Class = "TennoArmor",
	},
	Overguard = {
		Base = 0.0,
		StaticMax = false,
	},
	BaseDamageMultiplier = 0.0,
	CorpseDespawnDelay = 0.0,
	DisabledHumanoidStates = {},
	NewDefaultHumanoidState = Enum.HumanoidStateType.None,
} :: ActorBase.BaseSettings