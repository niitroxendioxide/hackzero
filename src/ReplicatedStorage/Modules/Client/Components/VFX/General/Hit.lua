---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local AudioLib = require(Client.Libraries.Audio)
local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

---
return function(
	Enemy: Types.EnemyClass,
	Data: {
		Emitter: string?, 
		Offset: CFrame?, 
		HueShift: number?, 
		HueShiftFilter: ((any) -> (number))?, HitstopTime: number?,
		Highlight: boolean?,

		Audio: {
			Id: string, 
			Volume: number?, 
			Priority: string?,
		}?,
	}
): ()

	Data = Data or {}

	local CombatFolder = Assets.Effects.General.Combat
	local EmitterId = Data.Emitter or 'Hit'

	if not CombatFolder:FindFirstChild(EmitterId) then
		print("Not found effect")

		return
	end

	local Offset = Data.Offset or CFrame.new()

	local Object = Effects:Create(CombatFolder[EmitterId], 25)
	Object.CFrame = Enemy:GetModel():GetPivot() * Offset

	if Data.HueShift or Data.HueShiftFilter then
		Effects:HueShift(Object, Data.HueShift or 0, Data.HueShiftFilter)
	end

	if Data.Highlight then
		local BaseColor = Data.HighlightColor or Color3.new(1, 0.870588, 0.709804)
		local H, S, V = BaseColor:ToHSV()
		H += Data.HueShift or 0
		if (H > 1) then H -= 1 elseif (H < -1) then H += 1 end

		local Highlight = Instance.new("Highlight")
		Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		Highlight.FillColor = Color3.fromHSV(H, S, V)
		Highlight.OutlineTransparency = 1
		Highlight.FillTransparency = 0
		Highlight.Parent = Enemy:GetModel()

		Effects:CleanUp(Highlight, .25)
		Effects:Tween(Highlight, {.25, 'Quad'}, {FillTransparency = 1})
	end

	if Data.Audio then
		AudioLib:PlayId(Data.Audio.Id, {
			At = Enemy:GetPivot().Position,
			Volume = Data.Audio.Volume or 1,
			Category = 'Effects',
			Priority = Data.Audio.Priority,
		})
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
