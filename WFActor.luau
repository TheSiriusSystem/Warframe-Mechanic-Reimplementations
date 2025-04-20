--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Const = require(ReplicatedStorage.Const)
local Events = ReplicatedStorage.Events
local ServerEvents = ServerStorage.Events

local ARMOR_VALUE: number = 300.0
local SHIELD_GATE_TIME: number = 0.1
local SHIELD_GATE_DAMAGE_MULTIPLIER: number = 0.05

local WFActor = {}
WFActor.__index = WFActor

function WFActor.new(character: Model): typeof(setmetatable({}, WFActor))?
	local self = setmetatable({}, WFActor)
	self.character = character
	self.humanoid = character:FindFirstChildWhichIsA("Humanoid")
	self.isShieldGatingActive = false
	self.shieldGateTime = 0.0
	self.timeSinceLastHit = 0.0
	self.connections = {}
	
	if not self.humanoid then
		warn(`WFActor.new: Character '{character.Name}' does not have a Humanoid.`)
		return nil
	end
	
	local function onMaxHealthChanged(): ()
		if self.humanoid.Health > self.humanoid.MaxHealth then
			self.humanoid.Health = self.humanoid.MaxHealth
		end
	end
	
	local function onShieldChanged(): ()
		local shield: number = self.humanoid:GetAttribute("Shield")
		local effectiveMaxShield: number = self:getEffectiveMaxShield()
		if shield < 0.0 or shield > effectiveMaxShield then
			self.humanoid:SetAttribute("Shield", math.clamp(shield, 0.0, effectiveMaxShield))
		end
	end
	
	local function onMaxShieldChanged(): ()
		local effectiveMaxShield: number = self:getEffectiveMaxShield()
		self.humanoid:SetAttribute("MaxShield", math.max(self.humanoid:GetAttribute("MaxShield"), 0.0))
		self.humanoid:SetAttribute("MaxOvershield", math.max(self.humanoid:GetAttribute("MaxOvershield"), 0.0))
		if self.humanoid:GetAttribute("Shield") > effectiveMaxShield then
			self.humanoid:SetAttribute("Shield", effectiveMaxShield)
		end
	end
	
	local function onOverguardChanged(): ()
		local overguard: number = self.humanoid:GetAttribute("Overguard")
		local maxOverguard: number = self.humanoid:GetAttribute("MaxOverguard")
		if overguard < 0.0 or overguard > maxOverguard then
			self.humanoid:SetAttribute("Overguard", math.clamp(overguard, 0.0, maxOverguard))
		end
	end
	
	local function onMaxOverguardChanged(): ()
		local maxOverguard: number = math.max(self.humanoid:GetAttribute("MaxOverguard"), 0.0)
		self.humanoid:SetAttribute("MaxOverguard", maxOverguard)
		if self.humanoid:GetAttribute("Overguard") > maxOverguard then
			self.humanoid:SetAttribute("Overguard", maxOverguard)
		end
	end
	
	local function onArmorChanged(): ()
		if self.humanoid:GetAttribute("Armor") < 0.0 then
			self.humanoid:SetAttribute("Armor", 0.0)
		end
	end
	
	-- Disable Roblox's default name tag.
	self.humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	self.humanoid.NameDisplayDistance = 0.0
	self.humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	self.humanoid.HealthDisplayDistance = 0.0
	
	onMaxHealthChanged()
	onShieldChanged()
	onMaxShieldChanged()
	onOverguardChanged()
	onMaxOverguardChanged()
	onArmorChanged()
	
	table.insert(self.connections, self.humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(onMaxHealthChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("Shield"):Connect(onShieldChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("MaxShield"):Connect(onMaxShieldChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("MaxOvershield"):Connect(onMaxShieldChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("Overguard"):Connect(onOverguardChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("MaxOverguard"):Connect(onMaxOverguardChanged))
	table.insert(self.connections, self.humanoid:GetAttributeChangedSignal("Armor"):Connect(onArmorChanged))
	
	-- Unregister the actor when the character is removed or the Humanoid dies. This is
	-- important for reducing load on the server.
	task.spawn(function(): ()
		while self.character.Parent and self.humanoid.Parent and self.humanoid.Health > 0.0 do
			self.humanoid:GetPropertyChangedSignal("Health"):Wait()
		end
		ServerEvents.UnregisterActor:Fire(self.character)
	end)
	
	CollectionService:AddTag(self.character, Const.TAG_ACTOR)
	
	return self
end

function WFActor:cleanup(): ()
	for _, connection in self.connections do
		connection:Disconnect()
		connection = nil
	end
end

function WFActor:update(deltaTime: number): ()
	if not self.humanoid or self.humanoid.Health <= 0.0 then
		return
	end
	
	if typeof(self.timeSinceLastHit) == "number" then -- Type check to silence a warning.
		self.timeSinceLastHit += deltaTime
	end
	
	-- Handle Shield Gating.
	if self.shieldGateTime > 0.0 then
		self.shieldGateTime -= deltaTime
		if self.shieldGateTime <= 0.0 and self.isShieldGatingActive then
			self.isShieldGatingActive = false
			print(`{self.character.Name}: Shield Gate expired.`)
		end
	end
	
	-- Handle Health regeneration.
	local healthRegenDelay: number = self.humanoid:GetAttribute("HealthRegenerationDelay")
	local healthRegenAmount: number = self.humanoid:GetAttribute("HealthRegenerationAmount")
	if healthRegenDelay >= 0.0 and healthRegenAmount > 0.0 and self.timeSinceLastHit >= healthRegenDelay and self.humanoid.Health < self.humanoid.MaxHealth then
		local healthToAdd: number = healthRegenAmount * deltaTime
		self.humanoid.Health = math.min(self.humanoid.MaxHealth, self.humanoid.Health + healthToAdd)
	end
	
	-- Handle Shield regeneration.
	local shield: number = self.humanoid:GetAttribute("Shield")
	local maxShield: number = self.humanoid:GetAttribute("MaxShield")
	local shieldRegenDelay: number = self.humanoid:GetAttribute("ShieldRegenerationDelay")
	local shieldRegenAmount: number = self.humanoid:GetAttribute("ShieldRegenerationAmount")
	if shieldRegenDelay >= 0.0 and shieldRegenAmount > 0.0 and self.timeSinceLastHit >= shieldRegenDelay and shield < maxShield then
		local shieldToAdd: number = shieldRegenAmount * deltaTime
		shield = math.min(maxShield, shield + shieldToAdd)
		self.humanoid:SetAttribute("Shield", shield)
	end
end

function WFActor:takeDamage(damage: number, isWeakSpot: boolean): ()
	if not self.humanoid then
		warn(`WFActor.takeDamage: Character '{self.character.Name}' does not have a Humanoid.`)
		return nil
	end
	
	if self.character:FindFirstChildWhichIsA("ForceField") or self.humanoid.Health <= 0.0 or damage <= 0.0 then
		return
	end
	
	self.timeSinceLastHit = 0.0
	
	-- For simplicity, Shield Gating works like how it does for Warframe enemies.
	-- See: https://wiki.warframe.com/w/Shield#Shield_Gating
	if self.isShieldGatingActive and not isWeakSpot then
		damage *= SHIELD_GATE_DAMAGE_MULTIPLIER
	end
	
	-- Reduce Overguard first. Overguard absorbs all forms of damage.
	local overguard: number = self.humanoid:GetAttribute("Overguard")
	if overguard > 0.0 then
		self.humanoid:SetAttribute("Overguard", overguard - damage)
		return
	end
	
	local damageRemaining: number = damage
	
	-- Second, reduce Shield. Excess damage spills over to Health.
	local shield: number = self.humanoid:GetAttribute("Shield")
	if shield > 0.0 then
		local damageDealtToShield: number = math.min(shield, damage)
		shield -= damageDealtToShield
		damageRemaining -= damageDealtToShield
		self.humanoid:SetAttribute("Shield", shield)
		Events.OnDamageTaken:FireAllClients(self.character, damageDealtToShield, Const.ODT_HEALTH_TYPE_SHIELD)
		
		if shield <= 0.0 and self.humanoid:GetAttribute("CanShieldGate") then
			self.isShieldGatingActive = true
			self.shieldGateTime = SHIELD_GATE_TIME
			print(`{self.character.Name}: Shield Gate triggered.`)
		end
	end
	
	-- Finally, reduce Health.
	if damageRemaining > 0.0 then
		-- 0 Armor = no damage reduction, no need for further checks here.
		damageRemaining *= (ARMOR_VALUE / (ARMOR_VALUE + self.humanoid:GetAttribute("Armor")))
		
		self.humanoid:TakeDamage(damageRemaining)
		Events.OnDamageTaken:FireAllClients(self.character, damageRemaining, Const.ODT_HEALTH_TYPE_HEALTH)
	end
end

function WFActor:getEffectiveMaxShield(): number
	if not self.humanoid then
		warn(`WFActor.getEffectiveMaxShield: Character '{self.character.Name}' does not have a Humanoid.`)
		return 0.0
	end
	return math.max(self.humanoid:GetAttribute("MaxShield") + self.humanoid:GetAttribute("MaxOvershield"), 0.0)
end

return WFActor