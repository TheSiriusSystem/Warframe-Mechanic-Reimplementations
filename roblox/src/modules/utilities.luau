--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Modules.Constants)
local Utils = {}

type InstancePropertiesPreset = "Hint"
type UiOverguardRenderStyle = "ProportionalFill" | "BorderFill"

local DAMAGE_EFFECT_COLOR_MULTIPLIER: number = 1.2
local DAMAGE_EFFECT_TWEEN_INFO: TweenInfo = TweenInfo.new(
	0.2,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)

-- Makes the given table and all nested tables read-only.
function Utils.deepFreezeTable(_table: {}): ()
	for key, value in pairs(_table) do
		if typeof(key) == "table" then
			key = Utils.deepFreezeTable(key)
		end
		if typeof(value) == "table" then
			value = Utils.deepFreezeTable(value)
		end
	end
	return table.freeze(_table)
end

-- Returns an instance of the specified class.
function Utils.instantiate(className: string, properties: {[string]: any} | InstancePropertiesPreset, parent: Instance, lifetime: number?, setNetworkOwnerToServer: boolean?): any
	local propertiesToSet: {[string]: any} = {}
	if typeof(properties) == "table" then
		propertiesToSet = properties
	elseif properties == "Hint" then
		propertiesToSet = {
			Transparency = 1.0,
			CastShadow = false,
			Size = Vector3.new(0.0, 0.0, 0.0),
			EnableFluidForces = false,
			Massless = true,
			Anchored = false,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		}
	end
	
	local instance = Instance.new(className)
	for property, value in pairs(propertiesToSet) do
		local attributeHintStart: number?, attributeHintEnd: number? = string.find(property, "attr_")
		if typeof(attributeHintEnd) ~= "number" then
			if property ~= "Parent" then
				instance[property] = value
			end
		else
			instance:SetAttribute(string.sub(property, attributeHintEnd + 1), value)
		end
	end
	instance.Parent = parent
	if setNetworkOwnerToServer == true and instance:IsA("BasePart") then
		instance:SetNetworkOwnershipAuto()
	end
	if typeof(lifetime) == "number" and lifetime > 0.0 then
		Debris:AddItem(instance, lifetime)
	end
	return instance
end

-- Returns the first child of the Instance with the given name for whom
-- Instance:IsA() returns true for the given className.
function Utils.findFirstChildOfClassAndName(instance: Instance, className: string, childName: string, recursive: boolean?): any
	if typeof(recursive) ~= "boolean" then
		recursive = false
	end
	
	local children: {Instance} = if not recursive then instance:GetChildren() else instance:GetDescendants()
	for _, child in children do
		if child:IsA(className) and child.Name == childName then
			return child
		end
	end
	return nil
end

-- Returns the child of the Instance with the given name for whom Instance:IsA()
-- returns true for the given className. If the child does not exist, it will
-- yield the current thread until it does.
function Utils.waitForChildWhichIsA(instance: Instance, className: string, timeOut: number?): any
	local child: Instance? = nil
	local timePassed: number = 0.0
	while true do
		local child = instance:FindFirstChildWhichIsA(className)
		if child then
			break
		end
		if typeof(timeOut) == "number" and timePassed >= timeOut then
			break
		end
		timePassed += task.wait()
	end
	return child
end

-- If the bit is not a number, it returns 0. If the bit is a number, it rounds
-- the bit and returns it.
function Utils.validateBitFlags(bit: number?): number
	if typeof(bit) ~= "number" then
		return 0
	end
	return math.round(bit)
end

-- Returns true if the bitwise AND of all provided numbers matches the expected
-- number.
function Utils.checkBitFlags(bit: number, flags: {number}): boolean
	local bitwiseAnd: number = 0
	for _, flag in ipairs(flags) do
		bitwiseAnd += flag
	end
	return (bit32.band(bit, bitwiseAnd) == bitwiseAnd)
end

-- Sets the attribute with the given name to the given value and returns it.
function Utils.setAndGetAttribute(instance: Instance, attributeName: string, value): any
	instance:SetAttribute(attributeName, value)
	return instance:GetAttribute(attributeName)
end

-- Returns two number attributes: Stat, MaxStat. 
function Utils.getCurrentAndMaxStat(instance: Instance, statName: string): (number, number)
	return instance:GetAttribute(statName), instance:GetAttribute("Max"..statName)
end

-- Returns the Humanoid's real name. If Humanoid.DisplayName is empty, it will
-- return the parent's name instead.
function Utils.getHumanoidName(humanoid: Humanoid): string
	if not humanoid.Parent then
		return ""
	end
	return if humanoid.DisplayName ~= "" then humanoid.DisplayName else humanoid.Parent.Name
end

function Utils.updateHealthBar(guiObject: GuiObject, actor: {[string]: any}, flags: number?, damageEffectIntensity: Vector2int16?): ()
	if not RunService:IsClient() then
		error("Utils.updateHealthBar() is client-only")
	end
	
	if typeof(flags) ~= "number" then
		flags = 0
	end
	if typeof(damageEffectIntensity) ~= "Vector2int16" then
		damageEffectIntensity = Vector2int16.new(8, 8)
	end
	
	-- NOTE: Damage detection is kinda bugged. Possibly there's another way?
	local function displayDamageEffect(attribute: number, currentAttribute: number, bar: Frame): ()
		if not Utils.checkBitFlags(flags, {Const.UIHealthBarFlags.NO_DAMAGE_EFFECT}) and attribute < currentAttribute then
			local effect: Frame = bar:Clone()
			effect.Name = "Effect"
			effect.AnchorPoint = Vector2.new(0.5, 0.5)
			effect.Position = UDim2.new(effect.Position.X.Scale + bar.Size.X.Scale, 0, 0.5, 0)
			effect.BackgroundColor3 = Color3.new(bar.BackgroundColor3.R * DAMAGE_EFFECT_COLOR_MULTIPLIER, bar.BackgroundColor3.G * DAMAGE_EFFECT_COLOR_MULTIPLIER, bar.BackgroundColor3.B * DAMAGE_EFFECT_COLOR_MULTIPLIER)
			effect.Size = UDim2.new(0.0, 0, effect.Size.Y.Scale, 0)
			effect.Parent = guiObject
			TweenService:Create(effect, DAMAGE_EFFECT_TWEEN_INFO, {
				BackgroundTransparency = 1.0,
				Size = UDim2.new(effect.Size.X.Scale, damageEffectIntensity.X, effect.Size.Y.Scale, damageEffectIntensity.Y)
			}):Play()
			Debris:AddItem(effect, DAMAGE_EFFECT_TWEEN_INFO.Time)
		end
	end
	
	local isFlipped: boolean = Utils.checkBitFlags(flags, {Const.UIHealthBarFlags.FLIP})
	local isUsingOverguardBorder: boolean = Utils.checkBitFlags(flags, {Const.UIHealthBarFlags.USE_OVERGUARD_BORDER})
	
	local guiObjectCast = guiObject :: any
	local shield: number, maxShield: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Shield")
	local armor: number, maxArmor: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Armor")
	local overguard: number, maxOverguard: number = Utils.getCurrentAndMaxStat(actor.humanoid, "Overguard")
	local relativeOverguard: number = if not isUsingOverguardBorder then overguard else 0.0
	local proportionTotal: number = actor.humanoid.MaxHealth + maxShield + relativeOverguard
	local healthProportion: number = actor.humanoid.Health / proportionTotal
	local shieldProportion: number = (if shield <= maxShield then shield else maxShield) / proportionTotal
	local overguardProportion: number = relativeOverguard / proportionTotal
	
	guiObjectCast.Bars.HealthBar.Position = UDim2.new(if not isFlipped then 0.0 else (maxShield + relativeOverguard) / proportionTotal, 0, 0.0, 0)
	guiObjectCast.Bars.HealthBar.Size = UDim2.new(healthProportion, 0, 1.0, 0)
	guiObjectCast.Bars.ShieldBar.Position = UDim2.new((if not isFlipped then actor.humanoid.MaxHealth else relativeOverguard) / proportionTotal, 0, 0.0, 0)
	guiObjectCast.Bars.ShieldBar.Size = UDim2.new(shieldProportion, 0, 1.0, 0)
	
	if not actor.character:FindFirstChildWhichIsA("ForceField") then
		local function updateUnarmoredHealthBar(): ()
			if not Utils.checkBitFlags(flags, {Const.UIHealthBarFlags.NO_OBJECT_HEALTH_COLOR}) and actor.baseSettings.Health.Class == "Object" then
				guiObjectCast.Bars.HealthBar.BackgroundColor3 = Const.BAR_COLOR_HEALTH_OBJECT
			else
				guiObjectCast.Bars.HealthBar.BackgroundColor3 = Const.BAR_COLOR_HEALTH_UNARMORED
			end
		end
		
		if not Utils.checkBitFlags(flags, {Const.UIHealthBarFlags.NO_ARMORED_HEALTH_COLOR}) then
			if armor <= 0.0 then
				updateUnarmoredHealthBar()
			else
				guiObjectCast.Bars.HealthBar.BackgroundColor3 = Const.BAR_COLOR_HEALTH_ARMORED
			end
		else
			updateUnarmoredHealthBar()
		end
		guiObjectCast.Bars.ShieldBar.BackgroundColor3 = if shield <= maxShield then Const.BAR_COLOR_SHIELD else Const.BAR_COLOR_OVERSHIELD
	else
		guiObjectCast.Bars.HealthBar.BackgroundColor3 = Const.BAR_COLOR_HEALTH_INVULNERABLE
		guiObjectCast.Bars.ShieldBar.BackgroundColor3 = Const.BAR_COLOR_SHIELD_INVULNERABLE
	end
	
	displayDamageEffect(actor.humanoid.Health, actor.currentHealth, guiObjectCast.Bars.HealthBar)
	displayDamageEffect(shield, actor.currentShield, guiObjectCast.Bars.ShieldBar)
		
	local armorIcon: ImageLabel? = Utils.findFirstChildOfClassAndName(guiObject, "ImageLabel", "ArmorIcon")
	if armorIcon then
		armorIcon.ImageTransparency = math.clamp(1.0 - (armor / maxArmor), 0.0, 1.0)
	end
	
	if not isUsingOverguardBorder then
		guiObjectCast.Bars.OverguardBar.Position = UDim2.new(if not isFlipped then (actor.humanoid.MaxHealth + maxShield) / proportionTotal else 0.0, 0, 0.0, 0)
		guiObjectCast.Bars.OverguardBar.BackgroundColor3 = Const.BAR_COLOR_OVERGUARD_FILLED
		guiObjectCast.Bars.OverguardBar.Size = UDim2.new(overguardProportion, 0, 1.0, 0)
	else
		local overguardRatio: number = overguard / maxOverguard
		if overguardRatio > 0.0 then
			guiObjectCast.Bars.OverguardBorder.Visible = true
			guiObjectCast.Bars.OverguardBorder.Left.BackgroundColor3 = if overguardRatio >= 0.02 then Const.BAR_COLOR_OVERGUARD_FILLED else Const.BAR_COLOR_OVERGUARD_UNFILLED
			guiObjectCast.Bars.OverguardBorder.Right.BackgroundColor3 = if overguardRatio >= 1.0 then Const.BAR_COLOR_OVERGUARD_FILLED else Const.BAR_COLOR_OVERGUARD_UNFILLED
			local fillXOffsetSize: number = 4
			if actor.humanoid.Health < actor.humanoid.MaxHealth * 0.2 then
				fillXOffsetSize = 0
			elseif actor.humanoid.Health < actor.humanoid.MaxHealth * 0.4 then
				fillXOffsetSize = 1
			elseif actor.humanoid.Health < actor.humanoid.MaxHealth * 0.6 then
				fillXOffsetSize = 2
			elseif actor.humanoid.Health < actor.humanoid.MaxHealth * 0.8 then
				fillXOffsetSize = 3
			end
			guiObjectCast.Bars.OverguardBorder.FillTop.Size = UDim2.new(overguardRatio, fillXOffsetSize, 0.0, 2)
			guiObjectCast.Bars.OverguardBorder.FillBottom.Size = guiObjectCast.Bars.OverguardBorder.FillTop.Size
		else
			guiObjectCast.Bars.OverguardBorder.Visible = false
		end
	end
end

function Utils.compileStatDisplay(value: number, color: Color3): string
	local function toRGB(value: number): number
		return math.round(value) * 255.0
	end
	return string.format("<font color=\"rgb(%s,%s,%s)\">"..math.round(value).."</font>", toRGB(color.R), toRGB(color.G), toRGB(color.B))
end

return Utils