--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Const)
local Events = ReplicatedStorage.Events

local HEALTH_BAR_Y_OFFSET: number = 65
local COLOR_HEALTH_UNARMORED: Color3 = Color3.fromRGB(204, 41, 41)
local COLOR_HEALTH_ARMORED: Color3 = Color3.fromRGB(223, 166, 53)
local COLOR_HEALTH_INVULNERABLE: Color3 = Color3.fromRGB(89, 89, 89)
local COLOR_SHIELD_NORMAL: Color3 = Color3.fromRGB(1, 214, 255)
local COLOR_SHIELD_OVER: Color3 = Color3.fromRGB(179, 1, 255)
local COLOR_SHIELD_INVULNERABLE: Color3 = Color3.fromRGB(156, 156, 155)
local DAMAGE_EFFECT_TWEEN_INFO: TweenInfo = TweenInfo.new(
	0.2,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out
)
local DAMAGE_EFFECT_INTENSITY: Vector2int16 = Vector2int16.new(8, 6)
local DAMAGE_EFFECT_COLOR_MULTIPLIER: number = 1.25
local DAMAGE_EFFECT_COOLDOWN: number = 0.01

local player = Players.LocalPlayer
local mouse: Mouse = player:GetMouse()
local targetHealthBar = player.PlayerGui:WaitForChild("TargetHealthBar")
local frame = targetHealthBar.Frame
local targetName: TextLabel = frame.TargetName
local healthFill: Frame = frame.Bar.HealthFill
local shieldFill: Frame = frame.Bar.ShieldFill
local overguardFill: Frame = frame.OverguardFill
local armorIcon: ImageLabel = frame.ArmorIcon
local currentTargetCharacter: Model?
local lastHealth: number = 0.0
local lastMaxHealth: number = 0.0
local lastShield: number = 0.0
local lastMaxShield: number = 0.0
local lastMaxOvershield: number = 0.0
local lastOverguard: number = 0.0
local lastMaxOverguard: number = 0.0
local lastArmor: number = 0.0
local timeSinceLastDamageEffect: number = DAMAGE_EFFECT_COOLDOWN

Events.OnDamageTaken.OnClientEvent:Connect(function(victim: Model, damage: number, healthType: string): ()
	if victim == currentTargetCharacter and damage > 0.0 and timeSinceLastDamageEffect >= DAMAGE_EFFECT_COOLDOWN then
		local newDamageEffect: Frame?
		local fill: Frame?
		
		if healthType == Const.ODT_HEALTH_TYPE_HEALTH then
			newDamageEffect = healthFill:Clone()
			fill = healthFill
		elseif healthType == Const.ODT_HEALTH_TYPE_SHIELD then
			newDamageEffect = shieldFill:Clone()
			fill = shieldFill
		else
			warn(`Unknown healthType '{healthType}'`)
		end
		
		if newDamageEffect and fill then
			newDamageEffect.Name = "Effect"
			newDamageEffect.AnchorPoint = Vector2.new(0.5, 0.5)
			newDamageEffect.Position = UDim2.fromScale(fill.Position.X.Scale + fill.Size.X.Scale, 0.5)
			newDamageEffect.Size = UDim2.fromScale(0.0, fill.Size.Y.Scale)
			newDamageEffect.BackgroundColor3 = Color3.new(fill.BackgroundColor3.R * DAMAGE_EFFECT_COLOR_MULTIPLIER, fill.BackgroundColor3.G * DAMAGE_EFFECT_COLOR_MULTIPLIER, fill.BackgroundColor3.B * DAMAGE_EFFECT_COLOR_MULTIPLIER)
			newDamageEffect.Parent = frame.Bar
			TweenService:Create(newDamageEffect, DAMAGE_EFFECT_TWEEN_INFO, {
				BackgroundTransparency = 1.0,
				Size = UDim2.new(newDamageEffect.Size.X.Scale, DAMAGE_EFFECT_INTENSITY.X, newDamageEffect.Size.Y.Scale, DAMAGE_EFFECT_INTENSITY.Y)
			}):Play()
			Debris:AddItem(newDamageEffect, DAMAGE_EFFECT_TWEEN_INFO.Time)
		end
	end
end)

RunService.PreRender:Connect(function(deltaTime: number): ()
	local mouseLocation: Vector2 = UserInputService:GetMouseLocation()
	frame.Position = UDim2.fromOffset(mouseLocation.X, mouseLocation.Y - frame.AbsoluteSize.Y - HEALTH_BAR_Y_OFFSET)
	
	local targetCharacter: Model?
	local targetHumanoid: Humanoid?
	
	local currentTarget: BasePart? = mouse.Target
	if currentTarget and currentTarget.Parent then
		targetCharacter = currentTarget:FindFirstAncestorWhichIsA("Model")
		if targetCharacter then
			targetHumanoid = targetCharacter:FindFirstChildWhichIsA("Humanoid")
			if not targetHumanoid or targetHumanoid.Health <= 0.0 or targetCharacter:HasTag(Const.TAG_FLAG_NO_HEALTH_BAR) then
				targetCharacter = nil
				targetHumanoid = nil
			end
		end
	end
	
	if targetCharacter and targetHumanoid then
		local shield: number = targetHumanoid:GetAttribute("Shield")
		local maxShield: number = targetHumanoid:GetAttribute("MaxShield")
		local maxOvershield: number = targetHumanoid:GetAttribute("MaxOvershield")
		local overguard: number = targetHumanoid:GetAttribute("Overguard")
		local maxOverguard: number = targetHumanoid:GetAttribute("MaxOverguard")
		local armor: number = targetHumanoid:GetAttribute("Armor")
		
		if targetCharacter ~= currentTargetCharacter or targetHumanoid.Health ~= lastHealth or targetHumanoid.MaxHealth ~= lastMaxHealth or shield ~= lastShield or maxShield ~= lastMaxShield or maxOvershield ~= lastMaxOvershield or overguard ~= lastOverguard or maxOverguard ~= lastMaxOverguard or armor ~= lastArmor then
			currentTargetCharacter = targetCharacter
			
			-- Cache important Humanoid information.
			lastHealth = targetHumanoid.Health
			lastMaxHealth = targetHumanoid.MaxHealth
			lastShield = shield
			lastMaxShield = maxShield
			lastMaxOvershield = maxOvershield
			lastOverguard = overguard
			lastMaxOverguard = maxOverguard
			lastArmor = armor
			
			-- Update the name label.
			targetName.Text = if targetHumanoid.DisplayName ~= "" then targetHumanoid.DisplayName else targetCharacter.Name
			
			-- Update the bar.
			local forceField: ForceField? = (currentTargetCharacter :: Model):FindFirstChildWhichIsA("ForceField")
			
			local maxTotal: number = lastMaxHealth + lastMaxShield -- Used for proportional scaling magic.
			local healthFillBaseScale: number = 0.0
			local shieldFillBaseScale: number = 0.0
			if maxTotal > 0.0 then -- IMPORTANT! Ensures that HealthFill and ShieldFill remain in place unless their maxima change.
				healthFillBaseScale = lastMaxHealth / maxTotal
				shieldFillBaseScale = lastMaxShield / maxTotal
			end
			local healthScale: number = if lastMaxHealth > 0.0 then math.clamp(lastHealth / lastMaxHealth, 0.0, 1.0) else 0.0
			healthFill.Size = UDim2.fromScale(healthScale * healthFillBaseScale, 1.0)
			if not forceField then
				healthFill.BackgroundColor3 = if lastArmor <= 0.0 then COLOR_HEALTH_UNARMORED else COLOR_HEALTH_ARMORED
			else
				healthFill.BackgroundColor3 = COLOR_HEALTH_INVULNERABLE	
			end
			local shieldScale: number = if lastMaxShield > 0.0 then math.clamp(lastShield / lastMaxShield, 0.0, 1.0) else 0.0
			shieldFill.Position = UDim2.fromScale(healthFillBaseScale, 0.0)
			shieldFill.Size = UDim2.fromScale(shieldScale * shieldFillBaseScale, 1.0)
			if not forceField then
				shieldFill.BackgroundColor3 = if lastShield > lastMaxShield then COLOR_SHIELD_OVER else COLOR_SHIELD_NORMAL
			else
				shieldFill.BackgroundColor3 = COLOR_SHIELD_INVULNERABLE
			end	
			local overguardScale: number = if lastMaxOverguard > 0.0 then math.clamp(lastOverguard / lastMaxOverguard, 0.0, 1.0) else 0.0
			overguardFill.Size = UDim2.fromScale(overguardScale, 1.0)
			armorIcon.Visible = lastArmor > 0.0
			
			if not frame.Visible then
				frame.Visible = true
			end
		end
	else
		if frame.Visible then
			currentTargetCharacter = nil
			
			-- Reset last known Humanoid information.
			lastHealth = 0.0
			lastMaxHealth = 0.0
			lastShield = 0.0
			lastMaxShield = 0.0
			lastMaxOvershield = 0.0
			lastOverguard = 0.0
			lastMaxOverguard = 0.0
			lastArmor = 0.0
			
			frame.Visible = false
		end
	end
end)

RunService.PostSimulation:Connect(function(deltaTime: number): ()
	timeSinceLastDamageEffect += deltaTime
end)