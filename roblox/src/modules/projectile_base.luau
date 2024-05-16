local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Const = require(ReplicatedStorage.Modules.Constants)
local Utils = require(ReplicatedStorage.Modules.Utilities)
local ProjectileBase = {Projectiles = {}}

function ProjectileBase.new(part: BasePart): {[string]: any}
	local projectile: {[string]: any} = ProjectileBase.Projectiles[part]
	if typeof(projectile) == "table" then
		return projectile
	end
	ProjectileBase.Projectiles[part] = {}

	projectile = ProjectileBase.Projectiles[part]
	projectile.object = part
end

return ProjectileBase