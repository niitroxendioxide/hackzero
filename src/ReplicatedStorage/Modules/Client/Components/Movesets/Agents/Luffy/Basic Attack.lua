--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(ReplicatedStorage.Modules.Client.Libraries.Animation)
local GameEnum = require(Shared.GameEnum) 
local Types = require(Shared.Types)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

Ability:ConnectHook(GameEnum.AbilityHooks.BeforeBeginConnection, function(Agent)
	Ability:Increase(Agent, 'Count', {Limit = 2})
end)

function Ability:Play(Caster: Types.GenericClass)
	local M1_Count = Ability:Get(Caster, 'Count')

	if Ability:Get(Caster, 'M1_Track') then
		Ability:Get(Caster, 'M1_Track'):Stop(0.125)
	end

	const Cleanup = Ability:Get(Caster, "M1_Cleanup");
	if Cleanup ~= nil then
		Cleanup()
	end

	--
	const Id = "Luffy.Abilities.M1."..M1_Count
	const AnimObject = Animation:GetAnim("Characters."..Id)
	local Track: AnimationTrack = nil;
	const BpAnims = {}
	
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
			Track = Ability:PlayAnimation(Caster, Id, {Active_Time = 0.45})

			for _, Object in Caster:GetModel():FindFirstChild("Parts"):GetChildren() do
				if M1_Count == 1 and Object.Name ~= 'RightArm' then
					continue
				end

				if M1_Count == 2 and Object.Name ~= 'LeftLeg' then
					continue
				end

				const Ctrl = Animation:Play(Object, AnimObject, 0, 1, Track.Speed)
				AddAnim(Ctrl)
			end

			Ability:Save(Caster, 'M1_Track', Track)
		end,},
	}, true)
	
	if M1_Count == 2 then
		Sequence:Add(0.783, function()
			for _, Object in Caster:GetModel():FindFirstChild("Parts"):GetChildren() do
				if M1_Count == 2 and Object.Name ~= 'LeftArm' then
					continue
				end

				StopAnims()
				const Ctrl = Animation:Play(Object, AnimObject, 0, 1, Track.Speed)
				Ctrl.TimePosition = 0.783
				AddAnim(Ctrl)
			end
		end)

		Sequence:Add(0.917, function(self, delta: number)
			Caster:WalkBack(0.225, 1.15)
		end)
	end

	Ability:Save(Caster, "M1_Cleanup", StopAnims)

	for i = 0, 0.9, 0.1 do
		const M1id = M1_Count + i
		const CurrentData = Ability:FromData("Attack_Data", M1id);
		if CurrentData == nil then
			continue;
		end

		const Size = Ability:FromData("Sizes", M1id)
		Ability:UseAttackData(Sequence, Caster, CurrentData, {
			Size = Size,
			Offset = vector.create(0, 0, -Size.Z/2),
			Hit_Function = function(Target)
				Ability:Hit(Caster, Target, {EffectData = {Highlight = true}, NoHitStop = true})
			end,
		})
	end

	Sequence:Start()
end

return Ability