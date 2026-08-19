local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local _GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('DragonBall')

ArtifactObject:OnHitProcess("After", function(Data, PieceCount: number): (number, number)
	if PieceCount < 4 then return end

	local Caster = Data.Agent;
	local HasEffect = Caster:GetEffect("DragonBall")
	local HasWish = Caster:HasTag("Wish")

	if HasWish then	
		return;
	end

	local AddedEffect = 0;
	if Data.Burst then
		AddedEffect += 3;
	end

	if Data.Critical then
		AddedEffect += 1;
	end

	if AddedEffect <= 0 then
		return
	end

	if HasEffect then
		local Total = math.clamp(HasEffect.Amount + AddedEffect, 0, 7);

		if Total >= 7 then
			Caster:RemoveEffect(HasEffect.Id)
			Caster:AddTag('Wish', 20, true)
			
			Caster:AddEffect({
				Tag = 'Wish',
				Time = 20,
				Type = 'Affliction_Aptitude',
				Value = 50,
				
			})

			Caster:AddEffect({
				Tag = 'Wish',
				Time = 20,
				Type = 'LA_Blunt%',
				Value = 15,
				Hide = true,
			})
		else
			Caster:ChangeEffect('DragonBall', AddedEffect);
		end

		return
	end

	Caster:AddEffect({
		Tag = 'DragonBall',
		Limit = 7,
	})

end)

return ArtifactObject
