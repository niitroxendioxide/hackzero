--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass)
	--
	

	Ability:Begin(Caster, {
		{0, function()
			Ability:PlayAnimation(Caster, "Test", {})
		end},

		{.367, function()
			Effects:Play("Glow", Caster)
		end}
	})
end

return Ability
