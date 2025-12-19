--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Client.Classes.Ability)

--
local Ability = AbilityClass.new()


local function Default(Caster: Types.Caster, Sequence: Types.Sequence)

    local function Hit(self)
        Ability:CreateHitbox(Caster, vector.zero, vector.one * 14, function(Enemy)
            Ability:Hit(Caster, Enemy, {})
        end)
    end

    for i = 1, 3 do
        Sequence:Add(0.25 + 0.033 * i, Hit)
    end
end

function Ability:Play(Caster: Types.Caster)

    local Seq = Ability:Begin(Caster, {
        {0, function()
            Ability:Effect("EnergyExplosion_Full", Caster)
            Ability:PlayAnimation(Caster, 'Goku.Abilities.Counter.Default', {})

            Caster:SwitchState('Attacking', Ability:FromData("Attack_State_Time"))
        end},
    }, true)

    Default(Caster, Seq); 
    Seq:Start();

end

return Ability