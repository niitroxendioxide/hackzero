---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Enemy: Types.EnemyClass, Data: {Emitter: string?, Offset: CFrame?})
	Data = Data or {}

	local CombatFolder = Assets.Effects.General.Combat
	local EmitterId = Data.Emitter or 'Hit'

	if not CombatFolder:FindFirstChild(EmitterId) then
		return
	end

	local Offset = Data.Offset or CFrame.new()

	local Object = Effects:Create(CombatFolder[EmitterId], 2.5)
	Object.CFrame = Enemy:GetPivot() * Offset

	Effects:Emit(Object)
end
