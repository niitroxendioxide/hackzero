---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)

---
return function(Enemy: Types.EnemyClass)
	--
	local Object = Effects:Create(Assets.Effects.General.Combat.Warning, 2.5)
	Object.CFrame = Enemy:GetModel().HumanoidRootPart.CFrame * CFrame.new(0, 0.65, 0)

	EffectsLib:Play('Glow', Enemy, {Color = Color3.new(1)})

	Effects:Weld(Object, Enemy:GetModel().PrimaryPart :: BasePart)

	Effects:Emit(Object)
end
