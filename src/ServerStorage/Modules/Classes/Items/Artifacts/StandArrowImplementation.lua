local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('StandArrow')
local UsedSkills = {}

ArtifactObject:OnHitProcess('Before', function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or (Data.SkillId ~= GameEnum.Skills.EX_Special) then
		return;
	end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("Resonance")
	if HasEffect and HasEffect.Amount >= 3 then
		Data.Multipliers.Daze *= 2;

		Caster:RemoveEffect(HasEffect.Id);
	end
end)

ArtifactObject:OnHitProcess("After", function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or Data.SkillId ~= GameEnum.Skills.EX_Special then return end

	local Caster = Data.Agent;
	if UsedSkills[Caster] == Data.SkillUniqueToken then
		return
	end

	local HasEffect = Caster:GetEffect("Resonance")
	if HasEffect then
		Caster:ChangeEffect('Resonance', 1, true);

		return
	end

	UsedSkills[Caster] = Data.SkillUniqueToken;

	---
	Caster:AddEffect({
		Tag = "Resonance",
		Type = 'Daze',
		Value = 4,
		Limit = 3,
	})
end)

return ArtifactObject
