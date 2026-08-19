local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('Sharingan')

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.AgentHurt, function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent
	local HasEffect = Caster:GetEffect("Insight")
	if HasEffect then
		Caster:ChangeEffect('Insight', -1, true);
	end
end)

ArtifactObject:OnHitProcess('After', function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or not Data.Critical  then
		return
	end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("Insight")
	if HasEffect then
		Caster:ChangeEffect('Insight', 1, true);

		return
	end

	Caster:AddEffect({
		Tag = 'Insight',
		Types = { 'Speed', 'Critical_Damage' },
		Values = { 0.02, 4 },
		Limit = 5,
		Time = 7,
	})
end)

return ArtifactObject
