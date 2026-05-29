--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass, _, _, Context)
	--
	--Ability:Save(Caster, 'Side', Ability:Get(Caster, 'Side') == 1 and 0 or 1)
	--(Ability:Get(Caster, 'Side') == 1 and 'Right' or 'Left')
	if Ability:Get(Caster, "Track") then
		Ability:Get(Caster, "Track"):Stop(0.1);
	end
	

	local Anim = Context.IsCancel and 'Back' or 'Forth'
	if not Context.IsCancel then
		Ability:Effect("Dodge_VFX", Caster)
	else
		Ability:Effect("Cancel", Caster)
	end

	local Sign = Context.IsCancel and -1 or 1;
	local IsOffCooldown = os.clock() - (Ability:Get(Caster, "LastSlashTime") or 0) > 1.5;
	Ability:Save(Caster, "LastSlashTime", os.clock())

	---
	Ability:Begin(Caster, {
		{0, function()
			local Track = Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Dodge.Dash'..Anim, {State = 'Dashing', Active_Time = 0.55})
			Ability:Save(Caster, 'Track', Track);

			Caster:SwitchState('Dashing', .3);
			Caster:ImpulseForward(Sign * Statics.Dash_Strength, Statics.Dash_Time)
		end},

		{0.1, function()
			if not(IsOffCooldown and Sign == -1) then
				return;
			end
			Ability:EffectSerial("Slash", Caster, -89, CFrame.new(0, 0, 0.75), true, 1.15)
		end},

		{0.2, function()
			if not(IsOffCooldown and Sign == -1) then
				return;
			end

			Ability:Save(Caster, "LastSlashTime", os.clock())
			Ability:CreateHitbox(Caster, vector.create(0, 0, -6.5), vector.create(12, 4, 14), function(Enemy)  
				Ability:Hit(Caster, Enemy, {EffectData = {
					Emitter = 'Hit',
					Highlight = true,
				}})
			end)
		end},
	}, true):Start()
end

return Ability
