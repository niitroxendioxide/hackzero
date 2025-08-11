---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(Enemy: Types.EnemyClass,
	Data: {Emitter: string?, Offset: CFrame?, HueShift: number?, HueShiftFilter: ((any) -> (number))?, HitstopTime: number?}
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

	task.delay(3/60, function()
		for _, Particle in Object:GetDescendants() do
			if Particle:IsA("ParticleEmitter") then
				local Time = Particle.TimeScale
				Particle.TimeScale = 0

				task.delay(Data.HitstopTime or 4/60, function()
					Particle.TimeScale = Time
				end)
			end
		end
	end)
end
