--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local AbilityClass = require(Client.Classes.Ability)
local Cutscenes = require(Client.Libraries.Cutscenes)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.AgentClass)
    Cutscenes:Start("ChihiroUltimate", Caster)

    local function HitEnemy()
        Ability:CreateHitbox(Caster, vector.zero, vector.create(54, 12, 54), function(Enemy)  
            Ability:Hit(Caster, Enemy, {
                EffectData = {
                    Emitter = "AkaHitVFX",
                    Highlight = true,
                    HighlightColor = Color3.new(1, 0.25, 0.25)
                }
            })
        end)
    end

    Ability:Begin(Caster, {
        {0, function()
            Caster:SwitchState('Attacking', Ability:FromData("Attack_State_Time"), true)

            Ability:PlayAnimation(Caster, 'Chihiro.Abilities.Ultimate.Default', { 
                Fade = 0.1,
            })
        end},

        {1.15, HitEnemy},
        {1.2, HitEnemy},
        {1.25, HitEnemy},
        {1.3, HitEnemy},
        {1.35, HitEnemy},
    })
end

return Ability