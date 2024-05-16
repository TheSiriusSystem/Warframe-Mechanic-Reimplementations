--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Const = require(ReplicatedStorage.Modules.Constants)
local Utils = require(ReplicatedStorage.Modules.Utilities)
local ActorBase = require(ServerStorage.Modules.ActorBase)

ReplicatedStorage.Events.Remotes.GetWFActor.OnServerInvoke = function(player: Player, character: Instance): {[string]: any}?
	return ActorBase.Actors[character]
end

ReplicatedStorage.Events.Remotes.GetAllWFActors.OnServerInvoke = function(player: Player): {[Instance]: {[string]: any}}
	return ActorBase.Actors
end

ServerStorage.Events.Bindables.TakeDamage.Event:Connect(function(character: Instance, damage: number, damageType: string, flags: number?, inflictor: Instance?, source: Instance?): ()
	local actor: {[string]: any}? = ActorBase.Actors[character]
	if typeof(actor) == "table" then
		flags = Utils.validateBitFlags(flags)
		
		local damageTypeData: {[string]: any} = Const.DAMAGE_TYPES[damageType]
		if typeof(damageTypeData) == "table" then
			local function setFlagIfAvailable(key: string, flag: number): ()
				if damageTypeData[key] == true and not Utils.checkBitFlags(flags, {flag}) then
					flags += flag
				end
			end
			
			setFlagIfAvailable("IgnoreShield", Const.DamageFlags.IGNORE_SHIELD)
			setFlagIfAvailable("IgnoreArmor", Const.DamageFlags.IGNORE_ARMOR)
		end
		
		if actor.canBeDamaged() then
			actor.onDamaged(damage, damageType, flags, inflictor, source)
		end	
	end
end)