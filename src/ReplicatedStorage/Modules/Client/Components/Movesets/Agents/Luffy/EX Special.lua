--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Caster: Types.GenericClass)
	const Cleanup = Ability:Get(Caster, 'M1_Cleanup') ;
	if Cleanup then
		Cleanup()
	end

	--
	const AnimId = "Luffy.Abilities.Special.Bazooka"
	const AnimObject = Animation:GetAnim("Characters."..AnimId)
	local Track: AnimationTrack = nil;
	local BpAnims = {}

	const function StopAnims() for _, v in BpAnims do v:Stop() end end
	const function AddAnim(T: AnimationTrack) 
		if Track then
			Track.Stopped:Once(function()
				T:Stop()
			end)
		end

		table.insert(BpAnims, T) 
	end

	const Sequence = Ability:Begin(Caster, {
		{0, function()
			Track = Ability:PlayAnimation(Caster, AnimId, {})
			Caster:SwitchState("Attacking", Ability:FromData("Attack_State_Time"))

			for _, Object in Caster:GetModel():FindFirstChild("Parts"):GetChildren() do
				if Object.Name ~= 'RightArm' and Object.Name ~= 'LeftArm' then
					continue
				end

				const Ctrl = Animation:Play(Object, AnimObject, 0, 1, Track.Speed)
				AddAnim(Ctrl)
			end

			Ability:Save(Caster, 'M1_Track', Track)
		end,},

		{0.517, function()
			Ability:Effect("Luffy_Bazooka", Caster)
			Ability:CreateHitbox(Caster, vector.create(0, 0, -10), vector.create(6, 6, 21), function(Target: Types.EnemyClass)
				Ability:Hit(Caster, Target, {
					EffectData = {Highlight = true},
					NoHitStop = true,
				})
			end)
		end},
	})

	Ability:Save(Caster, "M1_Cleanup", StopAnims)

	Sequence:Start()
end

return Ability