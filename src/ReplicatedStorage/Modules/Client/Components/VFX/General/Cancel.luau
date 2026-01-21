---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)

---
return function(Caster: Types.CharacterClass)
	--
	local Object = Effects:Create(Assets.Effects.General.Combat.CancelDodge, 2.5)
	Object.CFrame = Caster:GetModel().PrimaryPart.CFrame * CFrame.new(0, 0.65, 0)

	EffectsLib:Play('Glow', Caster, {Color = Color3.new(1, 1, 1)})

	Effects:FollowWithAlignments(Object, Caster:GetModel().Torso :: BasePart, 100000000, true)

	Effects:Emit(Object)
end
