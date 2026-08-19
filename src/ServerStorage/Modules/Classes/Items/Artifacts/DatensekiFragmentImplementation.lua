local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('DatensekiFragment')

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.AgentHurt, function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent
	local HasEffect = Caster:GetEffect("DatenM1Buff")
	if HasEffect then
		Caster:RemoveEffect(HasEffect.Id);
	end
end)

ArtifactObject:OnHitProcess("After", function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or Data.SkillId ~= GameEnum.Skills.Basic_Attack then return end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("DatenM1Buff")
	if HasEffect then
		Caster:ChangeEffect('DatenM1Buff', 1, true);

		return
	end

	---
	Caster:AddEffect({
		Tag = "DatenM1Buff",
		Value = 0.04,
		Limit = 10,
		Time = 15,
		RemovesAll = true,
		Type = 'Skill_Damage_'..GameEnum.Skills.Basic_Attack,
	})
end)

return ArtifactObject
