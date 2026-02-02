--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.GenericClass)
	--
	local Attack_Time = Ability:FromData("Attack_State_Time")

	Ability:Begin(Caster, {
		{0, function()
			
		end},

		{0.215, function()
			Ability:CreateHitbox(Caster, vector.create(0, 0, -4), vector.create(8, 8, 8), function(Target: Types.EnemyClass)  
				Ability:Hit(Caster, Target, {
					EffectData = {
						Highlight = true,
					}
				})
			end)
		end}
	})
end

return Ability
