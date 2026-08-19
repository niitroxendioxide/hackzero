local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local _GameEnum = require(Shared.GameEnum)

local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local ArtifactClass = require(Classes.Items.Artifact)

local Cooldowns = {}
local ArtifactObject = ArtifactClass.new('SukunasFinger')

ArtifactObject:OnHitProcess("Before", function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or not (Data.Critical or Data.Burst) then return end
	local HasEffect = Data.Agent:GetEffect("CursedEnergy")
	if (not HasEffect or HasEffect.Amount < 5) or Cooldowns[Data.Agent] then
		return;
	end

	Cooldowns[Data.Agent] = true;
	task.delay(7, function()
		Cooldowns[Data.Agent] = false
	end)

	Data.Agent:RemoveEffect(HasEffect.Id)

	Data.Multipliers.Damage *= 2;
	Data.Multipliers.Affliction *= 2;
	Data.Multipliers.Affliction_Buildup *= 2.5;

	Replicator:Effect("BlackFlash", {Data.Target:GetId(), Data.Agent}, true)
end)

ArtifactObject:OnHitProcess("After", function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 or not (Data.Critical or Data.Burst) then return end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("CursedEnergy")
	if HasEffect then
		Caster:ChangeEffect('CursedEnergy', 1)

		return
	end

	Caster:AddEffect({
		Tag = "CursedEnergy",
		Limit = 5,
		Time = 20,
	})
end)

return ArtifactObject
