---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

--local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types)
local AbilityTypes = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local GameEnum = require(Shared.GameEnum)
local LibEffects = require(Client.Libraries.Effects)

local Cache = {}
local MainText = {
	[GameEnum.Afflictions.Default] = 'DISORDER',
	[GameEnum.Afflictions.Earth] = 'QUAKE',
	[GameEnum.Afflictions.Water] = 'DROWN',
	[GameEnum.Afflictions.Fire] = 'IGNITE',
	[GameEnum.Afflictions.Ice] = 'FROZEN',
	[GameEnum.Afflictions.Electric] = 'SHOCK',
	[GameEnum.Afflictions.Energy] = 'SURGE',
	[GameEnum.Afflictions.Physical] = 'STRIKE',
	[GameEnum.Afflictions.Wind] = 'TEMPEST',
}

local SubText = {
	[GameEnum.Afflictions.Default] = 'DISORDER',
	[GameEnum.Afflictions.Earth] = 'FALTER',
	[GameEnum.Afflictions.Water] = 'ENGULF',
	[GameEnum.Afflictions.Fire] = 'BURN',
	[GameEnum.Afflictions.Ice] = 'SHATTER',
	[GameEnum.Afflictions.Electric] = 'PARALYZE',
	[GameEnum.Afflictions.Energy] = 'RELEASE',
	[GameEnum.Afflictions.Physical] = 'FLINCH',
	[GameEnum.Afflictions.Wind] = 'WINDSWEPT',
}

local Handlers = {
	[GameEnum.Afflictions.Energy] = function(Target: AbilityTypes.ClientEnemy)
		local AfflictionAssets = Assets.Effects.General.Combat.Afflictions
		local EnergyOrbs = Effects:Create(AfflictionAssets.Energy, 13)
		EnergyOrbs:PivotTo(Target:GetModel():GetPivot())
		Effects:Weld(EnergyOrbs.PrimaryPart, Target:GetModel().PrimaryPart)

		Cache[Target] = function()
			Effects:Toggle(EnergyOrbs, false)

			Cache[Target] = nil
		end

		task.delay(10, Cache[Target])
	end,

	[GameEnum.Afflictions.Ice] = function(Target: AbilityTypes.ClientEnemy, Shatter: boolean?, Time)
		local AfflictionAssets = Assets.Effects.General.Combat.Afflictions
		if Shatter then
			Time = math.floor(Time)

			local ShatterVFX = Effects:Create(AfflictionAssets.IceShatter, 3)
			ShatterVFX:PivotTo(Target:GetModel():GetPivot())
			Effects:Emit(ShatterVFX, true)

			LibEffects:Play("Indicator", Target, { 
				Number = Time,
				Affliction = 'Ice', 
				VanishTime = 1.5, 
				Burst = true, 
			})

			return
		end

		---
		LibEffects:Play("Hit", Target, { Emitter = 'AkaHitVFX', HueShift = 170})

		local TargetModel = Target:GetModel()
		local Highlight = Instance.new("Highlight")
		Highlight.FillColor = Color3.fromRGB(121, 237, 255)
		Highlight.FillTransparency = 0
		Highlight.OutlineColor = Color3.fromRGB(121, 237, 255)
		Highlight.Parent = TargetModel

		local IceAura = Effects:Create(AfflictionAssets.Ice, Time + 5)
		IceAura:PivotTo(Target:GetModel():GetPivot())
		Effects:Weld(IceAura.PrimaryPart, Target:GetModel().PrimaryPart)

		for _, ParticleEmitter in IceAura:GetDescendants() do
			if ParticleEmitter:IsA('ParticleEmitter') then
				if ParticleEmitter.Parent:IsA('Attachment') then
					Effects:Tween(ParticleEmitter, { .75, 'Quad', 'In' }, { TimeScale = 0.15 })
				end

				ParticleEmitter.Enabled = true;
			end
		end

		Effects:Tween(Highlight, { .15 }, {FillTransparency = 0.7, OutlineTransparency = 0.5})

		Cache[Target] = function()
			Highlight:Destroy()
			Effects:Toggle(IceAura, false)

			Cache[Target] = nil
		end

		task.delay(Time, Cache[Target])
	end
}

return function(Target: Types.GenericClass, Element: number, ...)
	if typeof(Target) == 'number' then
		Target = Enemies:GetEnemy(Target)
	end

	local Other = { ... }
	local UseSecondaryText = Other[1] == true

	local Affliction_Name = GameEnum.KeyLookup(GameEnum.Afflictions, Element)

	local Text = UseSecondaryText and SubText[Element] or MainText[Element]
	LibEffects:Play("Indicator", Target, { 
		Text = Text, 
		Critical = true, 
		Affliction = Affliction_Name, 
		VanishTime = 2, 
		Burst = true, 
		--ForceStroke = true 
	})

	if Cache[Target] then
		Cache[Target]()
		Cache[Target] = nil
	end

	if Handlers[Element] then
		Handlers[Element](Target, table.unpack(Other))
	end
end
