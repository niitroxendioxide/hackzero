---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)
local ForgeVFX = require(ReplicatedStorage.Packages.ForgeVFX)

---
return function(
	At: CFrame,
	Scale: number?
): ()

	Scale = Scale or 1

	local Effect = Effects:Create(Effects.General.Shockwaves.BulletShock, 3)
	Effect:PivotTo(At)

	for _, v in Effect:GetChildren() do
		ForgeVFX.emit(Scale, Effect)
	end
end
