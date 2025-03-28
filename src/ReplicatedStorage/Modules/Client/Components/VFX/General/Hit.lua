---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Enemy: Types.EnemyClass, Data: {})
	
	local Object = Effects:Create(Assets.Effects.General.Combat.Hit, 2.5)
	Object.CFrame = Enemy:GetPivot()
	
	Effects:Emit(Object)
	
end
