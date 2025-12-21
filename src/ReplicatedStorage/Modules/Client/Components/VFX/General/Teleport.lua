---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets.Effects
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local LibEffects = require(Client.Libraries.Effects)

---
return function(
	Caster: Types.Caster | CFrame,
	Offset: CFrame?
): ()
	Offset = Offset or CFrame.new()

	local Object = Effects:Create(Assets.Agents.Goku.Teleport, 25)
	if typeof(Caster) == 'CFrame' then
		Object.CFrame = Caster * Offset
	else
		Object:PivotTo(Caster:GetModel():GetPivot() * Offset)
		LibEffects:Play("Afterimage", Caster, Offset)
	end

	Effects:Emit(Object)
end
