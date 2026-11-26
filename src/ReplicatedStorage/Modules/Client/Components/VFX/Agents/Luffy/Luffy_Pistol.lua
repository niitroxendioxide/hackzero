---
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)


---
return function(
	Caster: Types.ClientAgent,
	id : number
): ()
	const LuffyAssets = Assets.Effects.Agents.Luffy
	const CasterModel = Caster:GetModel();

	const Side = id == 1 and -1 or 1
	const PistolVFX = Effects:Create(LuffyAssets.GomuPistol, 4)
	PistolVFX:PivotTo(CasterModel:GetPivot() * CFrame.new(0.446 * Side, 0.478, -8.275))
	Effects:Emit(PistolVFX, true)
end
