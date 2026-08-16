local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('HanafudaEarrings')

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.SkillCasted, function(Data, PieceCount)
	if PieceCount < 4 then return end

	local Caster = Data.Agent;
	if Data.SkillId == GameEnum.Skills.Dodge_Counter then
		local HasEffect = Caster:GetEffect("Concentration")

		if HasEffect then
			Caster:ChangeEffect('Concentration', 1);

			return
		end
		
		Caster:AddEffect({
			Tag = 'Concentration',
			Value = 7.5,
			Type = 'Affliction_Damage%',
			Time = 15,
			Limit = 4,
		})

	end
end)

return ArtifactObject
