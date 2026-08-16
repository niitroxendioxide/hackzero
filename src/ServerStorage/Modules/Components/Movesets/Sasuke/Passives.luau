---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Services = ServerStorage.Modules.Services

local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)
local AbilityService = require(Services.Combat.AbilityService)
local Types = require(Shared.Types.Agents)

---
local PassiveManager = {
    __Cache = {}
}

function PassiveManager:Init(Caster: Types.ServerAgentClass)
    AbilityService.DodgeSuccesful:Connect(function(Dodger: Types.ServerAgentClass, Attacker)
        if Dodger ~= Caster then
            return;
        end

        if PassiveManager:__is_active(Caster) then
            return
        end

        Caster:UpdateMeter("Sharingan", 1);
    end)
end

function PassiveManager:__set_active(Caster: Types.ServerAgentClass, State: boolean)
    PassiveManager.__Cache[Caster] = State
end

function PassiveManager:__is_active(Caster: Types.ServerAgentClass)
    return PassiveManager.__Cache[Caster] == true
end

function PassiveManager:OnPassiveFilled(Meter: string, Caster: Types.ServerAgentClass)
    if PassiveManager:__is_active(Caster) then
        return
    end

    local SharinganLengthTime = 22.5
    local DodgeHookId = HttpService:GenerateGUID()
    local LastDodge = 0

    Caster:AddTag("SharinganActive", SharinganLengthTime, true)

    AbilityService:ConnectVerificationHook(Caster, DodgeHookId, function(Perpetrator): boolean
        if (os.clock() - LastDodge) < 2 then
            Caster:AddTag("_sharingan_no_dodge", 2, true)
            return true
        end

        LastDodge = os.clock()
        Caster:AddTag('Dodge_Counter_Tag', Statics.Dodge_Counter_React_Time, true)
        Replicator:Effect('Sasuke_PassiveDodge', {Caster}, {Caster.__Player_Assigned})

        return false
    end)

    PassiveManager:__set_active(Caster, true)

    task.delay(SharinganLengthTime, function()
        Caster:UpdateMeter(Meter, -5)

        PassiveManager:__set_active(Caster, false)
        AbilityService:DisconnectVerificationHook(Caster, DodgeHookId)
    end)
end

return PassiveManager
