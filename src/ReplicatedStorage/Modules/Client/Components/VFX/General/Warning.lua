---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Enemy: Types.EnemyClass)
	--
	local Object = Effects:Create(Assets.Effects.General.Combat.Warning, 2.5)
	Object.CFrame = Enemy:GetPivot() * CFrame.new(0, 0.65, 0)

	Effects:Weld(Object, Enemy:GetModel().PrimaryPart :: BasePart)

	Effects:Emit(Object)
end
