local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes


local Types = require(Shared.Types.Companions)
local Abilities = require(Shared.Types.Abilities)
local AttackClass = require(Classes.Combat.ServerCompanionAttack)


local Ability = AttackClass.new()

function Ability:Run(Companion: Types.CompanionClass, Target: Abilities.Target)
    -- Do stuff here
    Ability:Sequence(Companion, {
        {0, function()

        end},

        {.25, function()
            Ability:Hit(Companion, Target, {
                Damage = Companion:GetStat("Attack"),
                Affliction = "Physical",
                Stun = 0.3,
            })
        end}
    })
end

return Ability
