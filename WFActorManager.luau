--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Const)
local WFActor = require(ServerStorage.WFActor)
local ServerEvents = ServerStorage.Events

local WFActorManager = {}

local actors: {[Instance]: typeof(WFActor.new(Instance.new("Model")))} = {}
local actorCleanupConnections: {[Instance]: RBXScriptConnection} = {}

function WFActorManager.registerActor(character: Model): typeof(WFActor.new(Instance.new("Model")))
	if not actors[character] then
		local actor = WFActor.new(character)
		if not actor then
			return nil -- Error handling is already done within WFActor.new().
		end
		
		actors[character] = actor
		actorCleanupConnections[character] = character.Destroying:Connect(function(): ()
			WFActorManager.unregisterActor(character)
		end)
		print(`WFActorManager: Registered actor '{character.Name}'.`)
		return actor
	end
	return nil
end

function WFActorManager.unregisterActor(character: Model): ()
	if actors[character] then
		(actors[character] :: any):cleanup() -- Typecast to any to silence a warning.
		actors[character] = nil
	end
	if actorCleanupConnections[character] then
		actorCleanupConnections[character]:Disconnect()
		actorCleanupConnections[character] = nil
	end
	print(`WFActorManager: Unregistered actor '{character.Name}'.`)
end

function WFActorManager.getActor(character: Model): typeof(WFActor.new(Instance.new("Model")))
	return actors[character]
end

function WFActorManager.getActorFromPart(part: BasePart): typeof(WFActor.new(Instance.new("Model")))?
	local character: Model? = part:FindFirstAncestorWhichIsA("Model")
	if character and actors[character] then
		return actors[character]
	end
	return nil
end

local function setupNPC(character: Model): ()
	if character:IsDescendantOf(workspace) and not character:HasTag(Const.TAG_FLAG_NO_AUTO_INIT) then
		WFActorManager.registerActor(character)
	else
		if character:IsDescendantOf(workspace) and character:HasTag(Const.TAG_FLAG_NO_AUTO_INIT) then
			print(`WFActorManager.setupNPC: Actor '{character.Name}' has the flag '{Const.TAG_FLAG_NO_AUTO_INIT}'.`)
		end
	end
end

local function setupPlayer(player: Player): ()
	local function registerCharacter(character: Model): ()
		local humanoid: Humanoid? = character:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			-- Setup attributes before registering the player as an actor first.
			humanoid:SetAttribute("Shield", 125.0)
			humanoid:SetAttribute("MaxShield", 125.0)
			humanoid:SetAttribute("MaxOvershield", 1200.0)
			humanoid:SetAttribute("Overguard", 0.0)
			humanoid:SetAttribute("MaxOverguard", 0.0)
			humanoid:SetAttribute("Armor", 50.0)
			humanoid:SetAttribute("HealthRegenerationDelay", -1.0)
			humanoid:SetAttribute("HealthRegenerationAmount", 0.0)
			humanoid:SetAttribute("ShieldRegenerationDelay", 3.0)
			humanoid:SetAttribute("ShieldRegenerationAmount", 25.0)
			humanoid:SetAttribute("CanShieldGate", true)
			print(`WFActorManager.setupPlayer: Set default attributes for '{character.Name}'.`)
			
			WFActorManager.registerActor(character)	
		end
	end
	
	player.CharacterAdded:Connect(registerCharacter)
	
	local character: Model? = player.Character
	if character then
		registerCharacter(character)
	end
end

ServerEvents.UnregisterActor.Event:Connect(WFActorManager.unregisterActor)

RunService.PostSimulation:Connect(function(deltaTime: number): ()
	for character, actor in actors do
		if actor then
			(actor :: any):update(deltaTime) -- Typecast to any to silence a warning.
		end
	end
end)

CollectionService:GetInstanceAddedSignal(Const.TAG_NPC):Connect(setupNPC)

Players.PlayerAdded:Connect(setupPlayer)

for _, npc in CollectionService:GetTagged(Const.TAG_NPC) do
	setupNPC(npc)
end

for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

return WFActorManager