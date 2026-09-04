--[[
    Kakashi's passive manager.

    Registered automatically by Kakashi/init.lua (any module named exactly 'Passives' is routed to
    SetPassiveManager), and driven by:
        TeamService     -> CreateMeter + OnMeterUpdated for every Moveset_Data.Passive.Meters entry
        AbilityService  -> TriggerMeterFullEvent when a meter hits 100% -> OnPassiveFilled below

    Charges themselves are granted by the ability modules through KakashiGameplayController:AddCharge
    whenever an Electric hit lands.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

---
local Shared = ReplicatedStorage.Modules.Shared
local Libraries = ServerStorage.Modules.Libraries

local Types = require(Shared.Types.Agents)
local Replicator = require(Libraries.Replicator)
local KakashiController = require(script.Parent.KakashiGameplayController)

---
local PassiveManager = {}

function PassiveManager:Init(_Caster: Types.ServerAgentClass)
    --[[
        Nothing to subscribe to: charges come from the ability modules calling
        KakashiController:AddCharge on Electric hits, rather than from a global signal.
        Kept so AbilityService's `PassiveManager.Init` check finds a function.
    ]]
end

--[[
    Fired when the Lightning meter fills (6/6). Per moveset.md this does NOT auto-enter the mode -
    it only makes it available; the player enters by holding Basic Attack, which routes to
    KakashiController:EnterLightningMode.
]]
function PassiveManager:OnPassiveFilled(_Meter: string, Caster: Types.ServerAgentClass)
    if KakashiController:IsLightningMode(Caster) then
        return
    end

    -- Prompt the owner that Lightning Mode is ready to be held into.
    Replicator:Effect('Kakashi_LightningReady', {Caster}, {Caster.__Player_Assigned})
end

return PassiveManager
