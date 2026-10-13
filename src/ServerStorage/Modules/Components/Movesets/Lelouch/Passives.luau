---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Services = ServerStorage.Modules.Services

local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types.Agents)
local EnemyLibrary = require(Shared.Libraries.Enemies)
local CharacterDatabase = require(Shared.Database.Characters)
local AbilityService = require(Services.Combat.AbilityService)
local LelouchController = require(script.Parent.LelouchGameplayController)

---
const TacticsData = CharacterDatabase:GetMovesetData('Lelouch').Passive.Tactics

local PassiveManager = {
    __Cache = {}
}

function PassiveManager:Init(Caster: Types.ServerAgentClass)
    AbilityService.SkillCasted:Connect(function(Agent: Types.ServerAgentClass, SkillId: number, Enemy: Types.Enemy?, StateId: number)
        if Agent == Caster or Agent.__Player_Assigned ~= Caster.__Player_Assigned then
            return
        end

        if SkillId ~= GameEnum.Skills.EX_Special or StateId ~= GameEnum.AbilityStates.Begin then
            return
        end

        if Caster:IsActive() or not Caster:IsAlive() then
            return
        end

        PassiveManager:GiveOrder(Caster, Agent, Enemy)
    end)
end

function PassiveManager:GiveOrder(Caster: Types.ServerAgentClass, Agent: Types.ServerAgentClass, Enemy: Types.Enemy?)
    const LastOrder = PassiveManager.__Cache[Caster] or 0
    if (os.clock() - LastOrder) < TacticsData.Cooldown then
        return
    end

    local Target = Enemy
    if not LelouchController:IsValidTarget(Target) then
        Target = select(2, EnemyLibrary:GetNearestEnemy(Agent:GetPivot().Position, TacticsData.Range))
    end

    if Target == nil then
        return
    end

    PassiveManager.__Cache[Caster] = os.clock()

    LelouchController:SetTarget(Caster, Target)
    LelouchController:SummonKnights(Caster, 1, Agent:GetPivot())
    LelouchController:ThrowGrenade(Caster, Target:GetPivot(), TacticsData.Grenade_Hit)
    LelouchController:ReplicateHit(Target)
end

function PassiveManager:OnPassiveFilled(_Meter: string, _Caster: Types.ServerAgentClass)
end

return PassiveManager
