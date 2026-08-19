local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('FiveLeafGrimoire')

ArtifactObject:OnHitProcess('After', function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or not (Data.SkillId == GameEnum.Skills.Basic_Attack)  then
		return
	end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("Rupture")
	if HasEffect then
		Caster:ChangeEffect('Rupture', 1);

		return
	end

	Caster:AddEffect({
		Tag = 'Rupture',
		Type = 'Pen_Ratio',
		Value = 2,
		Limit = 20,
		RemovesAll = true,
		Time = 30,
	})
end)

return ArtifactObject
