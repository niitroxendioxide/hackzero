---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Effects = require(Shared.Utility.Effects)

--
local Cache = {}

---
return function(Caster: Types.EnemyClass, State: string)
	--
	local SaiyanAssets = Assets.Effects.Enemies.Saiyan
	local CasterModel = Caster:GetModel()
	local RightHand = CasterModel:FindFirstChild('Right Arm')

	local function GetCF()
		return CFrame.lookAlong((RightHand.CFrame * CFrame.new(0, -2.5, 0)).Position, Caster:GetPivot().LookVector)
	end

	--
	if State == 'Charge' then
		if Cache[Caster] then
			return
		end

		--
		local ClonedBeam = Effects:Create(SaiyanAssets.SaiyanBeam1, 54)
		ClonedBeam:PivotTo(GetCF())
		ClonedBeam.Beam.Size = Vector3.new(0, 0.5, 0.5)

		Effects:Toggle(ClonedBeam.Moving, false)
		Effects:Toggle(ClonedBeam.AuraAround, false)
		Effects:Weld(ClonedBeam.Orb, RightHand).Name = 'ORBWELD'
		Cache[Caster] = ClonedBeam


		--
		ClonedBeam:ScaleTo(0.001)

		local kval = Instance.new('NumberValue')
		kval.Value = 0.001

		kval.Changed:Connect(function(k)
			ClonedBeam:ScaleTo(k)
		end)

		Effects:Tween(kval, {.2, 'Back'}, {Value = 1})
	elseif State == 'Shoot' then
		if not Cache[Caster] then
			return
		end

		local CF = Caster:GetPivot() * CFrame.new(0.392, 0.881, -2.737)
		local Beam = Cache[Caster]
		Beam.Orb.Anchored = true

		if Beam.Orb:FindFirstChild('ORBWELD') then
			Beam.Orb.ORBWELD:Destroy()
		end

		Effects:Toggle(Beam.AuraAround, true)
		Beam:PivotTo(CF)

		Beam.AuraAround.CFrame = CF * CFrame.new(0, 0, -30)
		Beam.Beam.CFrame = CF * CFrame.Angles(0, math.pi/2, 0)

		Beam.Beam.Transparency = 0
		Effects:Tween(Beam.Beam, {.36, 'Quad'}, {Size = Vector3.new(60, 0.5, 0.5), CFrame = Beam.Beam.CFrame * CFrame.new(30, 0, 0)})
		Effects:Tween(Beam.Moving, {.4}, {CFrame = Beam.Moving.CFrame * CFrame.new(0, 0, -60)})

		task.delay(.25, function()
			local m = Instance.new('Model')
			m.Parent = Beam
			Beam.Orb.Parent = m

			local value = Instance.new('NumberValue')
			value.Value = 1
			value.Changed:Connect(function(k)
				m:ScaleTo(k)
			end)

			Effects:Tween(value, {0.15}, {Value = 0.001})

			Effects:Tween(Beam.Beam, {.15, 'Sine'}, {Size = Vector3.new(60, 0, 0)})

			task.wait(.15)
			Beam.Beam.Transparency = 1
			Effects:Toggle(m, false)
		end)

		for _, Attachment in Beam.AuraAround:GetDescendants() do
			if Attachment:IsA('Attachment') then
				local Sign = Attachment.Name:match('S') and -1 or 1

				Attachment.Position = Vector3.new(0, 0, 30)


				Effects:Tween(Attachment, {.15}, {Position = Vector3.new(0, 0, Sign * 30)})
			elseif Attachment:IsA('Beam') then
				task.delay(.3, function()
					Effects:Tween(Attachment, {.225}, {Width0 = 0, Width1 = 0})
				end)

			end
		end

		--
		Cache[Caster] = nil
	end
end