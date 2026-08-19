local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('VivreCard')

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.AgentHurt, function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent
	local Hp, Max = Caster:GetHealth()
	local Percent = (Hp / Max)

	print(`Player is on: {Hp}, {Max}, ({Percent}) HP`)
end)

return ArtifactObject
