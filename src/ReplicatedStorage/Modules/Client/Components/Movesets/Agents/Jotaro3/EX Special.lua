--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local AgentTypes = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)
local Effects = require(Client.Libraries.Effects)


--
local RNG = Random.new()
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: AgentTypes.AgentClass, Binding: string, State: string)
	--
	local PreviousSequence = Ability:Get(Caster, "CurrentSequence")
	if State ~= 'Begin' then
		local _= PreviousSequence and PreviousSequence:Destroy()

		Caster:SwitchState('Attacking', 0)
		Ability:Save(Caster, "CurrentSequence", nil)

		return
	end

    if not Caster:GetEffect("StandSummoned") then
        return
    end

	local Attack_Time = Ability:FromData('Attack_State_Time')
	local LastEffClock = os.clock()
	local LastHitClock = os.clock()
	local Sequence = Ability:Begin(Caster, {
		{0, function(self)
			Caster:SwitchState('Attacking',  Attack_Time)

            Ability:Effect("JP3_Stand", Caster, {
                At = Vector3.new(0, 0, -3),
                Time = Attack_Time,
            })

            local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
			local StartTrack = Ability:PlayAnimation(Caster, "Jotaro3.Abilities.Special.Barrage_Start", {
                Model = StandModel,
            })
			self.__cache.track = StartTrack
		end},

		{.317, function(self)
            local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
            local Track = Ability:PlayAnimation(Caster, "Jotaro3.Abilities.Special.Barrage_Loop", {
                Model = StandModel,
                Speed = 2,
            })
			if self.__cache.track then
				self.__cache.track:Stop(0)
			end

			Ability:Save(Caster, 'CurrentLoop', Track)
		end},

		{0.317, Attack_Time, function(self)
			if (os.clock() - LastHitClock > Ability:FromData('Hit_Frequency')) then
				Caster:Walk(Ability:FromData("Walk_Time"))
				LastHitClock = os.clock()
			end

			if (os.clock() - LastEffClock > Ability:FromData('Effect_Frequency')) then
				LastEffClock = os.clock()

				Ability:CreateHitbox(Caster, Vector3.zAxis*-4, vector.create(5, 5, 9), function(Target: AgentTypes.ClientEnemy)
					Target:Hit()
					Ability:Effect('Hit', Target, {Emitter = 'BarrageEtherHit', Offset = CFrame.new(RNG:NextNumber(-1.5, 1.5), RNG:NextInteger(-1, 1), -1)})
				end)
			end
		end},
	})

	Sequence:After(function()
		local OtherTrack: AnimationTrack = Ability:Get(Caster, "CurrentLoop")
		if OtherTrack then
			OtherTrack:Stop(.15)
		end

        local StandModel = workspace.World.Effects:FindFirstChild(Caster.PlayerId..'SPstandmodel')
        Ability:PlayAnimation(Caster, "Jotaro3.Abilities.Special.Barrage_End", {
            Model = StandModel,
        })

        Ability:Effect("JP3_Stand", Caster, {
            At = Vector3.new(0, 0, -3),
            Time = 0.65,
        })
	end)

	Ability:Save(Caster, 'CurrentSequence', Sequence);
end

return Ability