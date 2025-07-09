--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.GenericClass, Binding: string, State: string)
	--
	local PreviousSequence = Ability:Get(Caster, "CurrentSequence")
	if State ~= 'Begin' then
		local _= PreviousSequence and PreviousSequence:Destroy()

		Caster:SwitchState('Attacking', 0)
		Ability:Save(Caster, "CurrentSequence", nil)

		return
	end

	local AttackTime = Ability:FromData('Attack_State_Time')
	local LastHitClock = os.clock()
	local Sequence = Ability:Begin(Caster, {
		{0, function(self: Types.Sequence)
			Caster:SwitchState('Attacking',  AttackTime)

			local StartTrack = Ability:PlayAnimation(Caster, "Goku.Abilities.Special.StartupEX", {})
			self.__cache.track = StartTrack

			Effects:Play("Glow", Caster)
		end},

		{.317, function(self: Types.Sequence)
			local Track = Ability:PlayAnimation(Caster, "Goku.Abilities.Special.LoopEX", {})
			if self.__cache.track then
				self.__cache.track:Stop(0)
			end

			Ability:Save(Caster, 'CurrentLoop', Track)
		end},

		{0.317, AttackTime, function(self)
			if (os.clock() - LastHitClock > Ability:FromData('Hit_Frequency')) then
				LastHitClock = os.clock()

				Caster:Walk(Ability:FromData("Walk_Time"))

				Ability:CreateHitbox(Caster, Vector3.zAxis*-3.4, Vector3.one * 5.75, function(Target: Types.EnemyClass)
					Target:Hit()
					Ability:Effect('Hit', Target)
				end)
			end
		end},
	})

	Sequence:After(function()
		local OtherTrack: AnimationTrack = Ability:Get(Caster, "CurrentLoop")
		if OtherTrack then
			OtherTrack:Stop(.15)
		end
	end)

	Ability:Save(Caster, 'CurrentSequence', Sequence);
end

return Ability
