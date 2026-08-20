---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)

---
local DodgeableHighlightColor = Color3.fromRGB(255, 185, 21)
local UndodgeableHighlightColor = Color3.new(255)

---
return function(Enemy: Types.EnemyClass, CanBeDodged: boolean)
	--
	if not Enemy or not Enemy:GetModel() or not Enemy:GetModel():FindFirstChild('HumanoidRootPart') then
		return
	end

	local Object = Effects:Create(Assets.Effects.General.Combat[CanBeDodged and 'Dodgeable' or 'Undodgeable'], 2.5)
	Object.CFrame = Enemy:GetModel().HumanoidRootPart.CFrame * CFrame.new(0, 0.65, 0)
	Effects:Weld(Object, Enemy:GetModel().PrimaryPart :: BasePart)
	Effects:Emit(Object)

	EffectsLib:Play('Glow', Enemy, {Color = CanBeDodged and DodgeableHighlightColor or UndodgeableHighlightColor})
end
