--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types)
--local GameEnum = require(Shared.GameEnum)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new(true)

function Ability:Play(Enemy: Types.EnemyClass)
    Ability:Increase(Enemy, "Counter", {Limit = 2})

	--
	if Ability:Get(Enemy, 'Punch_Track') then
		Ability:Get(Enemy, 'Punch_Track'):Stop()
	end

	--
	local Attack_Time = Ability:FromData('Attack_State_Time')
    local TrackId = "Punch"..Ability:Get(Enemy, "Counter")

	Ability:Begin(Enemy, {
		{0, function()
			Enemy:SwitchState('Attacking', Attack_Time / (Ability:FromData('Speed') or 1))

			local Track = Ability:PlayAnimation(Enemy, 'Saiyan.Abilities.'..TrackId, {
				Speed = Ability:FromData('Animation_Speed'),
				Fade = .1,
				Active_Time = Attack_Time,
			})

			Ability:Save(Enemy, 'Punch_Track', Track)
		end,},

        {.35, function()
            -- hitbox effect later :3
        end}
	})
end

return Ability