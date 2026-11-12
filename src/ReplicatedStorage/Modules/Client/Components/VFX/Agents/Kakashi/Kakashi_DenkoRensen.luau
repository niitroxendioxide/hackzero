--
local ReplicatedStorage = game:GetService('ReplicatedStorage')

const Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local LightningBolt = require(Client.Utility.Libraries.LightningBolt)

local BOLT_COUNT = 3
local COLOR = Color3.fromRGB(112, 150, 255)

local PULSE_SPEED = 12

---
return function(Caster: Types.AgentClass, Duration: number, Direction: number): ()
	local Model = Caster:GetModel()
	local Root = Model and Model.PrimaryPart
	if not Root then
		return
	end

	const KakashiVfx = Assets.Effects.Agents.Kakashi
	local Origin = Model.Torso:GetPivot().Position
	local Parent = Effects:GetParent()

	const DashVfx = Effects:Create(KakashiVfx.SmallBeams, 10)
	const Front = (Caster:GetPivot() * CFrame.new(4.628 * Direction, 0, -4.628)).Position
	DashVfx:PivotTo(CFrame.lookAt(Origin * vector.create(1, 0, 1) + vector.create(0, Root.Position.Y), Front))
	Effects:Emit(DashVfx, true)

	for _, Asset: Instance in DashVfx:GetDescendants() do
		if Asset:IsA('Beam') then
			local W0, W1 = Asset.Width0, Asset.Width1

			Asset.Width0, Asset.Width1 = 0, 0
			Effects:Tween(Asset, {0.65, 'Linear'}, {TextureSpeed = 0})
			Effects:Tween(Asset, {0.275, 'Back'}, {Width0 = W0, Width1 = W1})
			Effects:FadeOutBeams(Asset, {0.6})
		elseif Asset:IsA('Attachment') and Asset.Name == "End" then
			local Pos = Asset.Position;
			Asset.Position = vector.create(Pos.X, Pos.Y, -Pos.Z/2)

			Effects:Tween(Asset, { 0.3, 'Sine' }, { Position = Pos })
		end
	end

	for _ = 1, BOLT_COUNT do
		local Start = Instance.new('Attachment')
		Start.WorldPosition = Origin + Effects:RandomV3(0.5)
		Start.WorldAxis = Effects:RandomV3()
		Start.Parent = workspace.Terrain

		local Follow = Instance.new('Attachment')
		Follow.Position = vector.create(Effects:Random(-0.5, 0.5), Effects:Random(-1, 1), Effects:Random(-0.5, 0.5))
		Follow.WorldAxis = Effects:RandomV3()
		Follow.Parent = Model.Torso

		local CurveSize = Effects:Random(-3, 3)
		local Bolt = LightningBolt.new(Start, Follow, Effects:RandomInt(8, 14))
		Bolt.CurveSize0, Bolt.CurveSize1 = CurveSize, -CurveSize
		Bolt.PulseSpeed = PULSE_SPEED
		Bolt.PulseLength = Duration * PULSE_SPEED
		Bolt.ContractFrom = 0
		Bolt.MinRadius, Bolt.MaxRadius = 0.9, 2.25
		Bolt.Thickness = Effects:Random(0.15, 0.3)
		Bolt.Frequency = Effects:Random(0.2, 0.5)
		Bolt.Color = COLOR
		Bolt.Parent = Parent

		local Lifetime = (Bolt.PulseLength + 1) / PULSE_SPEED
		task.delay(Lifetime + 0.1, function()
			Start:Destroy()
			Follow:Destroy()
		end)
	end
end
