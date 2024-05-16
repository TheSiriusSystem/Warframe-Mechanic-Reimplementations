--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Modules.Constants)
local Utils = require(ReplicatedStorage.Modules.Utilities)

local NAME_TAG_DISPLAY_DISTANCE: number = 256.0

local player: Player = Players.LocalPlayer
local camera: Camera = workspace.CurrentCamera
local frame = script.Parent.Frame

RunService.Heartbeat:Connect(function(deltaTime: number): ()
	local mouseLocation: Vector2 = UserInputService:GetMouseLocation()
	local ray: Ray = camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
	local rayParams: RaycastParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	if player.Character then
		rayParams:AddToFilter(player.Character)
	end
	
	local result: RaycastResult? = workspace:Raycast(ray.Origin, ray.Direction * NAME_TAG_DISPLAY_DISTANCE, rayParams)
	if result then
		local target: Instance? = result.Instance.Parent
		if target then
			local targetActor: {[string]: any}? = nil
			while target ~= workspace do
				targetActor = ReplicatedStorage.Events.Remotes.GetWFActor:InvokeServer(target)
				if targetActor then
					break
				end
				target = target.Parent
			end
			
			if targetActor and targetActor.humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
				local targetAdornee: BasePart? = Utils.findFirstChildOfClassAndName(targetActor.character, "BasePart", "NameTagAttachment") or targetActor.head
				if targetAdornee then
					local targetLevel: number = targetActor.humanoid:GetAttribute("Level")
					
					-- Stabilizes the name tag's Y offset position at far distances.
					local vector: Vector3, isOnScreen: boolean = camera:WorldToViewportPoint(targetAdornee.Position)
					frame.Position = UDim2.new(0.0, vector.X, 0.0, vector.Y - (88 - math.min(vector.Z * 0.5, 24)))
					
					frame.Label.Text = if targetActor.humanoid.DisplayName ~= "" then targetActor.humanoid.DisplayName else targetActor.character.Name
					Utils.updateHealthBar(frame, targetActor, Const.UIHealthBarFlags.USE_OVERGUARD_BORDER, Vector2int16.new(6, 6))
					if targetLevel <= 0 or targetActor.baseSettings.HideLevel then
						frame.Level.Visible = false
					else
						frame.Level.Visible = true
						frame.Level.Label.Text = targetLevel
					end
					
					frame.Visible = true
					return
				end
			end
		end
	end
	frame.Visible = false
end)