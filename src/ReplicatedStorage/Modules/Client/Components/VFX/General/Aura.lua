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
		print('hello aura?')
		return;
	end

	local Enemy = Enemies:GetEnemy(EnemyId)
	if Enemy == nil then
		print('nil!', EnemyId, Enemies.__Enemies)
		return
	end

	local Model = Enemy:GetModel()

	local Clone = Effects:Create(BaseAura)
	Clone:PivotTo(Model:GetPivot())
	Effects:Weld(Clone, Model.PrimaryPart);

	print('no aura?')
end
