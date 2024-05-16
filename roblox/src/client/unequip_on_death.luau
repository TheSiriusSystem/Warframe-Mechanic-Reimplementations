--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utils = require(ReplicatedStorage.Modules.Utilities)

local player: Player = Players.LocalPlayer

player.CharacterAdded:Connect(function(character: Model): ()
	local humanoid: Humanoid? = Utils.waitForChildWhichIsA(character, "Humanoid", 1.0)
	if humanoid then
		humanoid.Died:Connect(function(): ()
			task.spawn(function(): ()
				while humanoid and task.wait() do
					humanoid:UnequipTools()
				end
			end)
		end)
	end
end)