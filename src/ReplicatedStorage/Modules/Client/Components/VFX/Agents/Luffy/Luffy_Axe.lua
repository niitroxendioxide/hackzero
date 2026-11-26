--[[
    Gomu Gomu no Axe impact. No dedicated asset yet - this stitches together pieces of existing
    explosions with their elemental parts stripped out:
      - Kakashi.ElectricExplosion  -> lightning / chromatic emitters removed
      - Sasuke.FireballHit         -> fire emitters removed
      - Sasuke.ExplosionMesh       -> Fire mesh removed, Smoke + Wind kept
    Whatever is left gets recolored to a neutral white, smoke takes the ground color.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Effects = require(Shared.Utility.Effects)

const Rng = Random.new()
const NEUTRAL = ColorSequence.new(Color3.fromRGB(255, 255, 255))
const STRIP_PATTERNS = {"lightning", "chromatic", "fire"}
const SMOKE_PATTERNS = {"smoke", "billowing", "cloud"}

const function Matches(Name: string, Patterns: { string }): boolean
	const Lower = string.lower(Name)
	for _, Pattern in Patterns do
		if string.find(Lower, Pattern, 1, true) then
			return true
		end
	end

	return false
end

-- Deletes elemental emitters and neutralizes the rest.
const function Neutralize(Object: Instance, GroundColor: Color3?)
	for _, Descendant in Object:GetDescendants() do
		if not Descendant:IsA("ParticleEmitter") then
			if Descendant:IsA("PointLight") then
				Descendant:Destroy()
			end

			continue
		end

		if Matches(Descendant.Name, STRIP_PATTERNS) then
			Descendant:Destroy()
		elseif Matches(Descendant.Name, SMOKE_PATTERNS) then
			if GroundColor then
				Descendant.Color = ColorSequence.new(GroundColor)
			end
		else
			Descendant.Color = NEUTRAL
		end
	end
end

return function(At: CFrame)
	const Ground = Effects:CastMapRaycast(At.Position, vector.create(0, -50, 0))
	const GroundColor = Ground and Ground.Color or nil
	const Base = Ground and CFrame.new(Ground.Position) * At.Rotation or At

	-- Main impact (the electric explosion's smack, smoke and rocks)
	const Impact = Effects:Create(Assets.Kakashi.ElectricExplosion, 4)
	Neutralize(Impact, GroundColor)
	Impact:PivotTo(Base)
	Effects:Emit(Impact)

	-- Burst on top (the fireball hit's impacts and wind wave)
	const Burst = Effects:Create(Assets.Sasuke.FireballHit, 3.65)
	Neutralize(Burst, GroundColor)
	Burst:PivotTo(Base * CFrame.new(0, 1.5, 0))
	Effects:Emit(Burst)

	-- Expanding shockwave meshes
	const Mesh = Effects:Create(Assets.Sasuke.ExplosionMesh, 2)
	const FireMesh = Mesh:FindFirstChild("Fire")
	if FireMesh then
		FireMesh:Destroy()
	end

	Mesh:PivotTo(Base)
	Effects:ForModelParts(Mesh, {
		Wind = function(Part)
			Effects:Tween(Part, { 0.6, 'Sine' }, {
				Transparency = 1,
				CFrame = Part.CFrame * Effects:RandomAngles(),
				Size = Part.Size * Rng:NextNumber(2, 2.75),
			})
		end,

		Smoke = function(Part)
			if GroundColor then
				Part.Color = GroundColor
			end

			Effects:Tween(Part, { 0.85, 'Sine' }, {
				Transparency = 1,
				CFrame = Part.CFrame * Effects:RandomAngles(),
			})
			Effects:Tween(Part, { 0.4, 'Quart' }, {
				Size = Part.Size * Rng:NextNumber(1.5, 1.8),
			})
			Part.Size *= 0
		end,
	})

	-- Crater + debris
	if Ground then
		Effects:CreateRocks(Ground, vector.create(2.4, 1.1, 2.4), {10, 13}, {6, 9}, {-15, 15}, Effects:GetParent(script.Name))
		Effects:ShootRocks(Ground, {6, 9}, {35, 55}, Effects:GetParent(script.Name))
	end

	Effects:ShakeCamera("Bump")
end
