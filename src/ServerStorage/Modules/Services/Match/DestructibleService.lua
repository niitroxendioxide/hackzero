-- Called by the match service so it's technically a library but whatever
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local GameEnum = require(Shared.GameEnum)
local Heap = require(Shared.Utility.Heap)
local Network = require(Shared.Network)
local Destructible = require(Modules.Classes.Game.Destructible)
local StructureDatabase = require(Shared.Database.Destructibles)

--
type StructureData = {
    Items: {
        [string]: number,
    }?,

    Effects: {
        [number]: {
            Type: string,
            Value: number,
            Time: number,
        }
    }?,

    Other: {
        Energy: number?,
    }?
}

--
local Replicate = function(Type: number, Data: buffer)
    local BufferLen = buffer.len(Data)
    local NewBuffer = buffer.create(BufferLen + 1)
    buffer.writeu8(NewBuffer, 0, Type)
    buffer.copy(NewBuffer, 1, Data, 0, BufferLen)

    Network:FireForAll("Replicate", NewBuffer)
end

--
local Service = {
    __Total_Destructibles = nil :: Heap.Heap?,
}

function Service:Init()
    --
    Service.__Total_Destructibles = Heap.new(255)
end

function Service:SetupStage(Structure_Map_Data: {})
    if not Structure_Map_Data then
        return
    end

    for _, StructureObj in Structure_Map_Data do
        local Id = StructureObj.Id
        if not Id then
            warn("No given ID for destructible:", StructureObj)

            continue
        end

        local Structure_Data = StructureDatabase:GetData(Id)
        if not Structure_Data then
            warn(`[{Id}] is not a valeid structure type.`)
            continue
        end

        for _, Part in StructureObj.Parts do
            local At = (Part.CFrame * CFrame.new(0, -Part.Size.Y/2, 0))
            Service:Create(Id, At, Structure_Data.Default_Structure_Data)
        end
    end

    table.clear(Structure_Map_Data)
end

function Service:Create(Type: string, At: CFrame, StructureData: StructureData?)
    --
    local Rotation = math.atan2(At.LookVector.X, At.LookVector.Y)
    print(Rotation)

    local DestructibleInstance = Destructible.new(Type, At.Position, Rotation)

    local DestructibleId = Service.__Total_Destructibles:extract()
    DestructibleInstance:Spawn(DestructibleId)

    DestructibleInstance.Destroyed:Connect(function(Caster: Types.ServerEnemyClass & AgentTypes.ServerAgentClass)
        Replicate(GameEnum.Replication.DestroyDestructible, DestructibleInstance:Compress(true))

        --
        if not StructureData then return end
        Service:GiveRewards(StructureData, Caster)
    end)

    local Objbuffer = DestructibleInstance:Compress()
    Replicate(GameEnum.Replication.CreateDestructible, Objbuffer)
end

function Service:GiveRewards(Data: StructureData, Caster: Types.ServerEnemyClass & AgentTypes.ServerAgentClass)
    local _Player: Player? = Caster.__Player_Assigned

    if Data.Other then
        if Data.Other.Energy and Caster.GiveEnergy then
            Caster:GiveEnergy(Data.Other.Energy)
        end
    end

    -- do other stuff here !
    if Data.Effects and Caster.AddEffect then
        for _, Effect in Data.Effects do
            Caster:AddEffect(Effect)
        end
    end
end

function Service:Sync()
    -- add later :3
end

return Service