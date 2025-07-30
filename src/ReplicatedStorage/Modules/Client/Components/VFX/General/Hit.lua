---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Enemy: Types.EnemyClass,
	Data: {Emitter: string?, Offset: CFrame?, HueShift: number?, HueShiftFilter: ((any) -> (number))?}
)

	Data = Data or {}

	local CombatFolder = Assets.Effects.General.Combat
	local EmitterId = Data.Emitter or 'Hit'

	if not CombatFolder:FindFirstChild(EmitterId) then
		print("Not found effect")

		return
	end

	local Offset = Data.Offset or CFrame.new()

	local Object = Effects:Create(CombatFolder[EmitterId], 25)
	Object.CFrame = Enemy:GetPivot() * Offset

	if Data.HueShift or Data.HueShiftFilter then
		Effects:HueShift(Object, Data.HueShift or 0, Data.HueShiftFilter)
	end

	Effects:Emit(Object)
end
