local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Utils = require(ReplicatedStorage.Modules.Utilities)
local ActorBase = require(ServerStorage.Modules.ActorBase)
local ActorAi = {}

export type AiSettings = {
	MeleeRange: number,
	MinAttackChance: number,
	Attacks: {
		[string]: {		
			Function: (target: BasePart, ...any) -> (),
			Condition: (target: BasePart) -> boolean,
		}
	},
}

function ActorAi.findNearestTarget(actor: {[string]: any}, searchDistance: number?): any
	if typeof(searchDistance) ~= "number" then
		searchDistance = 500.0
	end
	
	local foundTarget: Instance? = nil
	for _, targetActor in pairs(ActorBase.Actors) do
		if targetActor ~= actor and targetActor.root then
			local distance = (targetActor.root.Position - actor.root.Position).Magnitude
			if distance <= searchDistance then
				foundTarget = targetActor.root
				searchDistance = distance
			end
		end
	end
	return foundTarget
end

function ActorAi.moveToTarget(actor: {[string]: any}, target: BasePart, moveVariance: number?): ()
	if typeof(moveVariance) ~= "number" then
		moveVariance = 0.0
	end
	
	local random: Random = Random.new()
	actor.humanoid:MoveTo(target.Position + Vector3.new(random:NextNumber(-moveVariance, moveVariance), 0.0, random:NextNumber(-moveVariance, moveVariance)), target)
end

return ActorAi