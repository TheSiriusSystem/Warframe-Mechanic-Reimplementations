--!strict
local ServerStorage = game:GetService("ServerStorage")
local ActorBase = require(ServerStorage.Modules.ActorBase)

local actor: {[string]: any} = ActorBase.new(script.Parent)