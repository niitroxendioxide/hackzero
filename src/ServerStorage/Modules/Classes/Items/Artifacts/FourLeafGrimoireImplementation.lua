local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('FourLeafGrimoire')

ArtifactObject:OnEffectProcess(function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent;
	local HasTrigger = Caster:GetEffect("FourLeafEffect")
	if not HasTrigger then
		return;
	end
	
	local HasBuff = Caster:GetEffect("FourLeafBuff")
	if HasBuff then
		return;
	end

	Caster:RemoveEffect(HasTrigger.Id);
	Caster:AddEffect({
		Tag = 'FourLeafBuff',
		Type = 'Affliction_Damage%',
		Value = 20,
		Time = 17,
	})
end)

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.AgentSwitchedIn, function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("FourLeafEffect")
	if HasEffect then
		Caster:RefreshEffect('FourLeafEffect')

		return
	end

	Caster:AddEffect({
		Tag = 'FourLeafEffect',
		Type = 'Affliction_Facility',
		Value = 30,
		Hide = true,
		Time = 15,
	})
end)

return ArtifactObject
