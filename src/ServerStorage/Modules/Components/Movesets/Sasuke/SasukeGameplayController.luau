--[[
    niitroxendioxide 01-26-2026
    
    @service 
    Utility module for sasuke, helps me save the connected enemies & more, and handle the effects that relate to that.
    It's easier for me to handle connecting & disconnecting the threads for the fire moves n other stuff that relates to it.
    
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")    

---
local Types = require(ReplicatedStorage.Modules.Shared.Types.Agents)
local Replicator = require(ServerStorage.Modules.Libraries.Replicator)


---
local Threads = {}
local Sasuke = {}

function Sasuke:ConnectThread(Enemy: Types.Enemy, Caster: Types.ServerAgentClass)
    if Threads[Enemy] then
        task.cancel(Threads[Enemy])
    end

    Replicator:Effect("Sasuke_Thread", {Caster, Enemy:GetId(), 1}, true)

    Threads[Enemy] = task.delay(12, function()
        Replicator:Effect("Sasuke_Thread", {Caster, Enemy:GetId(), 2}, true)

        Threads[Enemy] = nil
    end)
end

function Sasuke:UseEnemyConnectedThreads(fn: (Types.Enemy) -> ()): ()
    for Enemy in Threads do
        task.spawn(fn, Enemy)

        task.cancel(Threads[Enemy])
        Threads[Enemy] = nil
    end
end

function Sasuke:HasConnectedThreads(): boolean
    for Enemy in Threads do
        return true
    end

    return false
end

return Sasuke;
