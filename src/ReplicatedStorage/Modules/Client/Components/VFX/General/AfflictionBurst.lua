---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
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
	[GameEnum.Afflictions.Ice] = 'SHATTER',
	[GameEnum.Afflictions.Electric] = 'SHOCK',
	[GameEnum.Afflictions.Energy] = 'SURGE',
	[GameEnum.Afflictions.Physical] = 'STRIKE',
	[GameEnum.Afflictions.Wind] = 'TEMPEST',
}

local _SubText = {
	[GameEnum.Afflictions.Default] = 'DISORDER',
	[GameEnum.Afflictions.Earth] = 'FALTER',
	[GameEnum.Afflictions.Water] = 'ENGULF',
	[GameEnum.Afflictions.Fire] = 'BURN',
	[GameEnum.Afflictions.Ice] = 'FROZEN',
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
}

return function(Target: Types.GenericClass, Element: number, Other: {  })
	local Affliction_Name = GameEnum.KeyLookup(GameEnum.Afflictions, Element)

	LibEffects:Play("Indicator", Target, { Text = MainText[Element], Critical = true, Affliction = Affliction_Name, VanishTime = 2.5, Burst = true, ForceStroke = true })

	if Cache[Target] then
		--[[LibEffects:Play("Indicator", Target, { 
			Text = MainText[GameEnum.Afflictions.Default], Critical = true, 
			Affliction = Affliction_Name, 
			VanishTime = 2.5, Burst = true, ForceStroke = true 
		})]]

		Cache[Target]()
		Cache[Target] = nil
	end

	if Handlers[Element] then
		Handlers[Element](Target)
	end
end
