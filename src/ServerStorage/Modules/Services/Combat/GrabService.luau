--[[
    @service Grabs Service
    
    Lets me grab enemies and join them into players so that i can make cool attacks
--]]

---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Agents)
local Agents = require(ServerStorage.Modules.Libraries.Agents)
local Network = require(Shared.Network)
local Enemies = require(Shared.Libraries.Enemies)
local GameEnum = require(Shared.GameEnum)

local Service = {
    __Grabs = {},
    __Enemies = {},
}


function Connect(Enemy: Types.Enemy, Caster: Types.ServerAgentClass, Offset: CFrame)
    local PlayerReplicationId = (Caster.__Player_Assigned:GetAttribute("ReplicationId") or 0)
    local AgentRelativeId = Agents:GetIdForPlayer(PlayerReplicationId, Caster)

    Enemy:AddTag("Grabbed")

    local BufferObj = buffer.create(4)
    buffer.writeu8(BufferObj, 0, GameEnum.Replication.BeginGrabEnemy)
    buffer.writeu8(BufferObj, 1, Enemy:GetId() :: number)
    buffer.writeu8(BufferObj, 2, PlayerReplicationId :: number)
    buffer.writeu8(BufferObj, 3, AgentRelativeId)
    
    Network:FireForAll("Replicate", BufferObj, Offset)
end

function Disconnect(Enemy: Types.Enemy, Caster: Types.ServerAgentClass)
    local PlayerReplicationId = (Caster.__Player_Assigned:GetAttribute("ReplicationId") or 0)
    local AgentRelativeId = Agents:GetIdForPlayer(PlayerReplicationId, Caster)

    
    Enemy:RemoveTag("Grabbed")

    local BufferObj = buffer.create(4)
    buffer.writeu8(BufferObj, 0, GameEnum.Replication.EndGrabEnemy)
    buffer.writeu8(BufferObj, 1, Enemy:GetId() :: number)
    buffer.writeu8(BufferObj, 2, PlayerReplicationId :: number)
    buffer.writeu8(BufferObj, 3, AgentRelativeId)
    
    Network:FireForAll("Replicate", BufferObj)
end

function Service:GrabEnemy(Caster: Types.ServerAgentClass, Enemy: Types.Enemy, Time: number?, Offset: CFrame?)
    local EnemyId = Enemy:GetId()

    if table.find(Service.__Enemies, EnemyId) then
        return
    end

    if Service.__Grabs[Caster] == nil then
        Service.__Grabs[Caster] = {}
    end

    table.insert(Service.__Enemies, EnemyId);

    Connect(Enemy, Caster, Offset)
    Enemy:SetGrabbedBy(Caster, Offset)

    --
    Service.__Grabs[Caster][EnemyId] = task.delay(Time, function()
        local Index = table.find(Service.__Enemies, EnemyId)
        if Index then
            table.remove(Service.__Enemies, Index);
        end

        Service.__Grabs[Caster][EnemyId] = nil

        Enemy:SetGrabbedBy(nil, nil)
        Disconnect(Enemy, Caster)
    end)
end

function Service:GetGrabbedEnemies(Caster: Types.ServerAgentClass, Enemy: Types.Enemy): { Types.Enemy }
    local List = {};

    if not Service.__Grabs[Caster] then
        return List
    end

    for EnemyId in Service.__Grabs[Caster] do
        table.insert(List, Enemies:GetEnemy(EnemyId))
    end

    return List
end

function Service:ForceStopGrab(Enemy: Types.Enemy)
    local EnemyId = Enemy:GetId()

    for Caster, List in Service.__Grabs do
        for KeyId, Thread in List do
            if KeyId == EnemyId then
                if Thread ~= coroutine.running() and typeof(Thread) == 'thread' then
                    task.cancel(Thread)
                end

                local Index = table.find(Service.__Enemies, EnemyId)
                if Index then
                    table.remove(Service.__Enemies, Index);
                end

                Service.__Grabs[Caster][KeyId] = nil
                Enemy:SetGrabbedBy(nil, nil)

                Disconnect(Enemy, Caster)
            end
        end
    end
end

return Service