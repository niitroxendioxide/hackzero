---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Effects
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)

---
return function(EnemyId: number, Aura: string)
	local BaseAura = Assets:FindFirstChild(Aura or 'Affected_Aura', true)
	if not BaseAura then
		return;
	end

	local Enemy = Enemies:GetEnemy(EnemyId)
	if Enemy == nil then
		return
	end

	local Model = Enemy:GetModel()

	local LimbsFolder = BaseAura:FindFirstChild('Limbs')
	local Body = BaseAura:FindFirstChild('Body')

	if LimbsFolder then
		for _, Limb in {'Right Arm', 'Left Arm', 'Left Leg', 'Right Leg', 'Torso', 'Head'} do
			local BodyPart = Model:FindFirstChild(Limb)
			if not BodyPart then
				continue
			end

			for _, LimbVFX in LimbsFolder:GetChildren() do
				local Cloned = Effects:Create(LimbVFX, nil, BodyPart)
				Cloned.Name = 'Affected_Aura'
			end
		end
	end

	if Body then
		local Clone = Effects:Create(Body)
		Clone:PivotTo(Model:GetPivot())
		Effects:Weld(Clone, Model.PrimaryPart);
	end
end
