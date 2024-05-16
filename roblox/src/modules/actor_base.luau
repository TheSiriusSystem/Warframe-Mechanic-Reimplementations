local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Modules.Constants)
local Utils = require(ReplicatedStorage.Modules.Utilities)
local ActorBase = {Actors = {}}

type HumanoidAttribute = {
	Value: number,
	Min: number?,
	Max: number?,
}
export type ActorTag = "Organic" | "Robotic" | "Aerial" | "Naval" | "Massive" | "Armored" | "Miniboss" | "Boss" | "Structure"
export type BaseSettings = {
	Tags: {ActorTag},
	HideLevel: boolean, -- If true, the actor's Level won't be shown when hovered over.
	Health: {
		Base: number, -- The Health this actor starts with.
		Class: string, -- The Health type this actor has. If set to Object, its Health bar will use a different color and any Status Effects will be nullified.
		RegenAmount: (deltaTime: number) -> number,
	},
	Shield: {
		Base: number, -- The Shield this actor starts with.
		Class: string, -- The Shield type this actor has.
		Impenetrable: boolean, -- If true, the IGNORE_SHIELD damage flag's effects will be nullified.
		RegenAmount: (deltaTime: number) -> number,
	},
	Armor: {
		Base: number, -- The Armor this actor starts with.
		Class: string, -- The Armor type this actor has.
	},
	Overguard: {
		Base: number?, -- The Overguard this actor starts with. If set to 0, Overguard attributes will not be set.
		StaticMax: boolean, -- If true, MaxOverguard will not change if Overguard is 0 or higher than MaxOverguard.
	},
	BaseDamageMultiplier: number,
	CorpseDespawnDelay: number, -- The amount of seconds it takes for the actor to be destroyed after death.
	DisabledHumanoidStates: {Enum.HumanoidStateType}, -- List of Humanoid states to disable during initialization. Useful for optimization.
	NewDefaultHumanoidState: Enum.HumanoidStateType, -- Changes the default Humanoid state. Has niche use cases.
}

local NAME_OVERGUARD_GATE: string = "OverguardGate"
local HUMANOID_ATTRIBUTE_FLOAT_RAW: HumanoidAttribute = {
	Value = 0.0,
}
local HUMANOID_ATTRIBUTE_FLOAT_MIN_0: HumanoidAttribute = {
	Value = 0.0,
	Min = 0.0,
} 
local HUMANOID_ATTRIBUTES: {[string]: HumanoidAttribute} = {
	Level = {
		Value = 1,
		Min = 0,
		Max = 9999,
	},
	Shield = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	MaxShield = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	MaxOvershield = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	Armor = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	MaxArmor = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	Overguard = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	MaxOverguard = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	DamageMultiplier = {
		Value = 1.0,
		Min = 0.0,
	},
	HealthRegenDelay = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	ShieldRegenDelay = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
	HealthDamageModifier = HUMANOID_ATTRIBUTE_FLOAT_RAW,
	ShieldDamageModifier = HUMANOID_ATTRIBUTE_FLOAT_RAW,
	OverguardDamageModifier = HUMANOID_ATTRIBUTE_FLOAT_RAW,
	OverguardGateDuration = HUMANOID_ATTRIBUTE_FLOAT_MIN_0,
}

function ActorBase.new(character: Instance, setNetworkOwnerToServer: boolean?): {[string]: any}?
	if typeof(character) ~= "Instance" then
		return nil
	end
	
	-- If the actor already exists, return it instead. Otherwise, create a new table
	-- and initialize the rest.
	local actor: {[any]: any} = ActorBase.Actors[character]
	if typeof(actor) == "table" then
		return actor
	end
	ActorBase.Actors[character] = {}
	actor = ActorBase.Actors[character]
	
	-- BaseSettings holds important variables.
	-- AISettings is optional and holds variables for use in AI and attacks.
	actor.character = character
	actor.humanoid = actor.character:FindFirstChildWhichIsA("Humanoid")
	actor.root = Utils.findFirstChildOfClassAndName(actor.character, "BasePart", "HumanoidRootPart")
	actor.head = Utils.findFirstChildOfClassAndName(actor.character, "BasePart", "Head")
	actor.healthRegenTime = 0.0
	actor.shieldRegenTime = 0.0
	actor.baseSettings = Utils.deepFreezeTable(require(Utils.findFirstChildOfClassAndName(actor.character, "ModuleScript", "BaseSettings")))
	local aiSettings: ModuleScript? = Utils.findFirstChildOfClassAndName(actor.character, "ModuleScript", "AISettings")
	if aiSettings then
		actor.aiSettings = Utils.deepFreezeTable(require(aiSettings))
	end
	
	-- On the server, an actor can be queried by requiring `ActorBase` and writing
	-- `ActorBase.Actors[character]` and on the client, invoking RemoteFunction
	-- `GetWFActor` accomplishes the same thing. To be removed?
	if not actor.character:HasTag(Const.TAG_ACTOR) then
		actor.character:AddTag(Const.TAG_ACTOR)
	end
	
	-- This should not be used if you are calling ActorBase.new() on players.
	if setNetworkOwnerToServer == true then
		for _, part in ipairs(actor.character:GetDescendants()) do
			if part:IsA("BasePart") and not part.Anchored then
				part:SetNetworkOwner(nil)
			end
		end
	end
	
	for _, state in ipairs(actor.baseSettings.DisabledHumanoidStates) do
		actor.humanoid:SetStateEnabled(state, false)
	end
	if actor.baseSettings.NewDefaultHumanoidState ~= Enum.HumanoidStateType.None then
		actor.humanoid:ChangeState(actor.baseSettings.NewDefaultHumanoidState)
	end
	
	for name, data in pairs(HUMANOID_ATTRIBUTES) do
		local value = actor.humanoid:GetAttribute(name)
		if typeof(value) ~= typeof(data.Value) then
			value = data.Value
		end
		
		local isMinValid: boolean = (typeof(data.Min) == "number")
		local isMaxValid: boolean = (typeof(data.Max) == "number")
		if not isMinValid and not isMaxValid then
			actor.humanoid:SetAttribute(name, value)
		elseif isMinValid and isMaxValid then
			actor.humanoid:SetAttribute(name, math.clamp(value, data.Min, data.Max))
		elseif isMinValid and not isMaxValid then
			actor.humanoid:SetAttribute(name, math.max(value, data.Min))
		elseif not isMinValid and isMaxValid then
			actor.humanoid:SetAttribute(name, math.min(value, data.Max))
		end
	end
	actor.changedConnections = {
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("Shield"):Connect(function(): ()
				local shield: number, maxShield: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Shield")
				actor.humanoid:SetAttribute("Shield", if actor.humanoid:GetState() ~= Enum.HumanoidStateType.Dead then math.clamp(shield, 0.0, maxShield + actor.humanoid:GetAttribute("MaxOvershield")) else 0.0)
			end),
			DisconnectOnDestroy = false,
		},
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("MaxShield"):Connect(function(): ()
				local shield: number, maxShield: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Shield")
				maxShield = Utils.setAndGetAttribute(actor.humanoid, "MaxShield", math.max(maxShield, 0.0))
				actor.humanoid:SetAttribute("Shield", math.min(shield, maxShield + actor.humanoid:GetAttribute("MaxOvershield")))
			end),
			DisconnectOnDestroy = true,
		},
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("MaxOvershield"):Connect(function(): ()
				actor.humanoid:SetAttribute("MaxOvershield", math.max(actor.humanoid:GetAttribute("MaxOvershield"), 0.0))
			end),
			DisconnectOnDestroy = true,
		},
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("Armor"):Connect(function(): ()
				local armor: number = actor.humanoid:GetAttribute("Armor")
				armor = Utils.setAndGetAttribute(actor.humanoid, "Armor", math.max(armor, 0.0))
				if armor <= 0.0 or (armor > 0.0 and actor.humanoid:GetAttribute("MaxArmor") <= 0.0) then
					actor.humanoid:SetAttribute("MaxArmor", armor)
				end
			end),
			DisconnectOnDestroy = true,
		},
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("Overguard"):Connect(function(): ()
				if actor.humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
					local overguard: number, maxOverguard: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Overguard")
					
					if not actor.baseSettings.Overguard.StaticMax then
						overguard = Utils.setAndGetAttribute(actor.humanoid, "Overguard", math.max(overguard, 0.0))
						if overguard > maxOverguard or overguard <= 0.0 then
							actor.humanoid:SetAttribute("MaxOverguard", overguard)
						end
					else
						overguard = Utils.setAndGetAttribute(actor.humanoid, "Overguard", math.clamp(overguard, 0.0, maxOverguard))
					end
					
					local overguardGateDuration: number = actor.humanoid:GetAttribute("OverguardGateDuration")
					if overguardGateDuration > 0.0 then
						if overguard > 0.0 then
							actor.canUseOverguardGate = true
						elseif actor.canUseOverguardGate and not Utils.findFirstChildOfClassAndName(actor.character, "ForceField", NAME_OVERGUARD_GATE) then
							actor.canUseOverguardGate = false
							Utils.instantiate("ForceField", {
								Name = NAME_OVERGUARD_GATE,
							}, character, overguardGateDuration)
						end
					end
				else
					actor.humanoid:SetAttribute("Overguard", 0.0)
				end
			end),
			DisconnectOnDestroy = false,
		},
		{
			Connection = actor.humanoid:GetAttributeChangedSignal("MaxOverguard"):Connect(function(): ()
				local overguard: number, maxOverguard: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Overguard")
				if maxOverguard < 0.0 then
					maxOverguard = Utils.setAndGetAttribute(actor.humanoid, "MaxOverguard", math.max(maxOverguard, 0.0))
				end
				actor.humanoid:SetAttribute("Overguard", math.min(overguard, maxOverguard))
			end),
			DisconnectOnDestroy = true,
		},
	} :: {
		{
			Connection: RBXScriptConnection,
			DisconnectOnDestroy: boolean,
		}
	}
	
	ActorBase.scaleStatsWithLevel(actor)
	actor.humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	actor.humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	actor.humanoid.NameDisplayDistance = 0.0
	actor.humanoid.HealthDisplayDistance = 0.0
	
	actor.currentHealth = actor.humanoid.Health
	actor.currentShield = actor.humanoid:GetAttribute("Shield")
	actor.canUseOverguardGate = (actor.humanoid:GetAttribute("Overguard") > 0.0)
	
	actor.canBeDamaged = function(): boolean
		return true
	end
	
	actor.onDamaged = function(damage: number, damageType: string, flags: number?, inflictor: Instance?, source: Instance?): ()
		flags = Utils.validateBitFlags(flags)
		
		if not Utils.checkBitFlags(flags, {Const.DamageFlags.IGNORE_INVULNERABLE}) and actor.character:FindFirstChildWhichIsA("ForceField") then
			return
		end
		
		local damageTypeData: {[string]: any}? = Const.DAMAGE_TYPES[damageType]
		
		local function getTypeModifier(healthType: string): number
			if typeof(damageTypeData) == "table" then
				local classModifiers: {[string]: number}? = damageTypeData[healthType]
				if typeof(classModifiers) == "table" then
					local classModifier: number? = classModifiers[actor.baseSettings[healthType].Class]
					if typeof(classModifier) == "number" then
						return classModifier
					end
				elseif typeof(classModifiers) == "number" then
					return classModifiers
				end
			end
			return 0.0
		end
		
		local function addModifier(modifier: number): number
			return 1.0 + modifier
		end
		
		local healthDamageModifier: number = addModifier(actor.humanoid:GetAttribute("HealthDamageModifier"))
		local shieldDamageModifier: number = addModifier(actor.humanoid:GetAttribute("ShieldDamageModifier"))
		local overguardDamageModifier: number = addModifier(actor.humanoid:GetAttribute("OverguardDamageModifier"))
		
		local function damageHealth(amount: number): ()
			local consideredArmor: number = if not Utils.checkBitFlags(flags, {Const.DamageFlags.IGNORE_ARMOR}) then actor.humanoid:GetAttribute("Armor") else 0.0
			local healthTypeModifier: number = if not Utils.checkBitFlags(flags, {Const.DamageFlags.IGNORE_HEALTH_CLASS}) then getTypeModifier("Health") else 0.0
			local armorTypeModifier: number = if consideredArmor > 0.0 then getTypeModifier("Armor") else 0.0
			actor.humanoid.Health -= amount * addModifier(healthTypeModifier) * addModifier(armorTypeModifier) * healthDamageModifier * 300.0 / (300.0 + consideredArmor * (1.0 - armorTypeModifier))
		end
		
		local shield: number = actor.humanoid:GetAttribute("Shield")
		local overguard: number = actor.humanoid:GetAttribute("Overguard")
		
		if not Utils.checkBitFlags(flags, {Const.DamageFlags.IGNORE_OVERGUARD}) and overguard > 0.0 then
			actor.humanoid:SetAttribute("Overguard", overguard - (damage * addModifier(getTypeModifier("Overguard")) * overguardDamageModifier))
			return
		end
		
		if (Utils.checkBitFlags(flags, {Const.DamageFlags.IGNORE_SHIELD}) and not actor.baseSettings.Shield.Impenetrable) or shield <= 0.0 then
			damageHealth(damage)
			return
		end
		
		local newShield: number = shield - (damage * addModifier(getTypeModifier("Shield")) * shieldDamageModifier)
		if newShield < 0.0 then
			damageHealth(-newShield)
		end
		actor.humanoid:SetAttribute("Shield", newShield)
	end
	
	actor.onDied = function(): ()
		
	end
	
	actor.regenConnection = RunService.Heartbeat:Connect(function(deltaTime: number): ()
		local shield: number, maxShield: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Shield")
		
		if actor.humanoid:GetAttribute("HealthRegenDelay") > 0.0 and actor.humanoid.Health < actor.humanoid.MaxHealth then
			if actor.humanoid.Health < actor.currentHealth then
				actor.healthRegenTime = 0.0
				if shield <= 0.0 then
					actor.shieldRegenTime = 0.0
				end
			end
			if actor.healthRegenTime < actor.humanoid:GetAttribute("HealthRegenDelay") then
				actor.healthRegenTime += deltaTime
			else
				actor.humanoid.Health += actor.baseSettings.Health.RegenAmount(deltaTime)
			end
		end
		actor.currentHealth = actor.humanoid.Health
		--print("HealthRegenTime: "..actor.healthRegenTime.." | "..actor.humanoid:GetAttribute("HealthRegenDelay"))
		
		if actor.humanoid:GetAttribute("ShieldRegenDelay") > 0.0 and shield < maxShield then
			if shield < actor.currentShield then
				actor.shieldRegenTime = 0.0
			end
			if actor.shieldRegenTime < actor.humanoid:GetAttribute("ShieldRegenDelay") then
				actor.shieldRegenTime += deltaTime
			else
				shield = Utils.setAndGetAttribute(actor.humanoid, "Shield", math.min(shield + actor.baseSettings.Shield.RegenAmount(deltaTime), maxShield))
			end
		end
		actor.currentShield = shield
		--print("ShieldRegenTime: "..actor.shieldRegenTime.." | "..actor.humanoid:GetAttribute("ShieldRegenDelay"))
	end)
	actor.diedConnection = actor.humanoid.Died:Connect(function(): ()
		actor.onDied()
		
		actor.currentHealth = 0.0
		actor.currentShield = 0.0
		actor.humanoid:SetAttribute("Shield", 0.0)
		actor.humanoid:SetAttribute("Armor", 0.0)
		actor.humanoid:SetAttribute("Overguard", 0.0)
		
		if typeof(actor.regenConnection) == "RBXScriptConnection" then
			actor.regenConnection:Disconnect()
			actor.regenConnection = nil
		end
		for _, _table in ipairs(actor.changedConnections) do
			if _table.DisconnectOnDestroy == true then
				_table.Connection:Disconnect()
				_table.Connection = nil
			end
		end
		actor.diedConnection:Disconnect()
		actor.diedConnection = nil
		if actor.baseSettings.CorpseDespawnDelay > 0.0 then
			Debris:AddItem(character, actor.baseSettings.CorpseDespawnDelay)
		end
	end)
	actor.character.Destroying:Connect(function(): ()
		ActorBase.clear(actor.character)
	end)
	
	return actor
end

function ActorBase.clear(character: Model): ()
	if typeof(ActorBase.Actors[character]) == "table" then
		ActorBase.Actors[character] = nil
		print("Removed unused data for "..character.Name)
	end
end

function ActorBase.setDamageModifiers(actor: {[string]: any}, damageModifier: number, setOverguardDamageModifier: boolean?): ()
	actor.humanoid:SetAttribute("HealthDamageModifier", damageModifier)
	actor.humanoid:SetAttribute("ShieldDamageModifier", damageModifier)
	if setOverguardDamageModifier == true then
		actor.humanoid:SetAttribute("OverguardDamageModifier", damageModifier)
	end
end

--[[
Resets the character's Health, Shield, Armor, and Overguard to their base values, and scales them by Level.

NOTE: Formulas were sourced from https://warframe.fandom.com/wiki/MediaWiki:EnemyInfoboxSlider.js
]]
function ActorBase.scaleStatsWithLevel(actor: {[string]: any}, settingOverrides: {[string]: any}?): ()
	local level: number = math.max(actor.humanoid:GetAttribute("Level") - 1, 0)
	
	local function calculateMultiplier(oldValue: number, newValue: number, transitionStartLevel: number?, transitionEndLevel: number?): number
		if typeof(transitionStartLevel) ~= "number" then
			transitionStartLevel = 70
		end
		if typeof(transitionEndLevel) ~= "number" then
			transitionEndLevel = 80
		end
		
		local transition: number = (level - transitionStartLevel :: number) / (transitionEndLevel :: number - transitionStartLevel :: number)
		local smoothstep: number = 3.0 * math.pow(transition, 2.0) - 2.0 * math.pow(transition, 3.0)
		if level < transitionStartLevel then
			smoothstep = 0.0
		elseif level > transitionEndLevel then
			smoothstep = 1.0
		end
		return oldValue * (1.0 - smoothstep) + newValue * smoothstep
	end
	
	local function setCustomStat(attributeName: string, value: number, optional: boolean?): ()
		if optional ~= true or value <= 0.0 then
			actor.humanoid:SetAttribute("Max"..attributeName, value)
			actor.humanoid:SetAttribute(attributeName, value)
		end
	end
	
	actor.humanoid.MaxHealth = math.round(actor.baseSettings.Health.Base * calculateMultiplier(1.0 + 0.015 * math.pow(level, 2), 1.0 + 24.0 * math.sqrt(level) * math.sqrt(5.0) / 5.0))
	actor.humanoid.Health = actor.humanoid.MaxHealth
	setCustomStat("Shield", math.round(actor.baseSettings.Shield.Base * calculateMultiplier(1.0 + 0.020 * math.pow(level, 1.75), 1.0 + 1.6 * math.pow(level, 0.75))))
	setCustomStat("Armor", actor.baseSettings.Armor.Base * calculateMultiplier(1.0 + 0.005 * math.pow(level, 1.75), 1.0 + 0.4 * math.pow(level, 0.75)))
	setCustomStat("Overguard", math.round(actor.baseSettings.Overguard.Base * calculateMultiplier(1.0 + 0.0015 * math.pow(level, 4.0), 1.0 + 260.0 * math.pow(level, 0.9), 45, 50)), true)
	actor.humanoid:SetAttribute("DamageMultiplier", actor.baseSettings.BaseDamageMultiplier * (1.0 + 0.015 * math.pow(level, 1.55)))
end

return ActorBase