--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ActorBase = require(ServerStorage.Modules.ActorBase)

local BASE_SETTINGS_PRESET: ModuleScript = script.PlayerBaseSettings

function onDescendantAdded(descendant: Instance): ()
	if descendant:IsA("Humanoid") and descendant.Parent and Players:GetPlayerFromCharacter(descendant.Parent) then
		local baseSettings: ModuleScript = BASE_SETTINGS_PRESET:Clone()
		baseSettings.Name = "BaseSettings"
		baseSettings.Parent = descendant.Parent
		descendant:SetAttribute("MaxOvershield", 1200.0)
		descendant:SetAttribute("OverguardGateDuration", 0.5)
		descendant:SetAttribute("HealthRegenDelay", 5.0)
		descendant:SetAttribute("ShieldRegenDelay", 4.0)
		ActorBase.new(descendant.Parent, false)
	elseif descendant:IsA("ForceField") then
		descendant.Visible = false
	end
end

workspace.DescendantAdded:Connect(onDescendantAdded)

for _, descendant in ipairs(workspace:GetDescendants()) do
	onDescendantAdded(descendant)
end