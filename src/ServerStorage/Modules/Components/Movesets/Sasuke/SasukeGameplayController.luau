--[[
    niitroxendioxide 01-26-2026
    
    @service 
    Utility module for sasuke, helps me save the connected enemies & more, and handle the effects that relate to that.
    It's easier for me to handle connecting & disconnecting the threads for the fire moves n other stuff that relates to it.
    
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")    

---
local Statics = require(ReplicatedStorage.Modules.Shared.Database.Statics)
local Types = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)


---
local Threads = {}
local Sasuke = {}

function Sasuke:ConnectThread(Enemy: Types.Enemy, Caster: Types.ServerAgentClass)
    if not Threads[Caster] then
        Threads[Caster] = {}
    end

    if Threads[Caster][Enemy] then
        task.cancel(Threads[Caster][Enemy])
    end

    Replicator:Effect("Sasuke_Thread", {Caster, Enemy:GetId(), 1}, true)
    Caster:AddTag(Statics.Agent_Tags.Sasuke.Has_Enemies_Connected, nil, true)

    Threads[Caster][Enemy] = task.delay(12, function()
        Replicator:Effect("Sasuke_Thread", {Caster, Enemy:GetId(), 2}, true)
        if not Sasuke:HasConnectedThreads() then
            Caster:RemoveTag(Statics.Agent_Tags.Sasuke.Has_Enemies_Connected)
        end

        Threads[Caster][Enemy] = nil
    end)
end

function Sasuke:UseEnemyConnectedThreads(Caster: Types.ServerAgentClass, fn: (Types.Enemy) -> ()): ()
    Caster:RemoveTag(Statics.Agent_Tags.Sasuke.Has_Enemies_Connected)
    
    for Enemy in (Threads[Caster] or {}) do
        task.spawn(fn, Enemy)

        task.cancel(Threads[Caster][Enemy])
        Threads[Caster][Enemy]= nil
    end
end

function Sasuke:HasConnectedThreads(Caster: Types.ServerAgentClass): boolean
    for Enemy in (Threads[Caster] or {}) do
        return true
    end

    return false
end

return Sasuke;
