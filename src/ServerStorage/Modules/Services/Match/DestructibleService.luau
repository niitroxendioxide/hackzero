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
local Signal = require(Shared.Utility.Signal)
local Destructible = require(Modules.Classes.Game.Destructible)
local LootService = require(Modules.Services.Match.LootService)
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
    }?,

    Drops: {
        [number]: {
            Type: string,
            Amount: number,
            Extra: {
                Name: string?,
            }
        }
    }?,

    SetValues: {
        [string]: (number | boolean)?,
    }?,
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
    StructureSetValuesEvent = nil :: Types.Signal<{[string]: boolean}>,
}

function Service:Init()
    --
    Service.__Total_Destructibles = Heap.new(255)
    Service.StructureSetValuesEvent = Signal.new() :: Types.Signal<{[string]: boolean}>
end

function Service:SetupStage(Structure_Map_Data: {}, Mission_Structure_Data: {})
    if not Structure_Map_Data then
        return
    end

    for Key, StructureObj in Structure_Map_Data do
        local Type = StructureObj.Type
        if not Type then
            warn("No given Type for destructible:", StructureObj)

            continue
        end

        local Id = StructureObj.Id
        local Structure_Data = StructureDatabase:GetData(Type)
        if not Structure_Data then
            warn(`[{Type}] is not a valeid structure type.`)
            continue
        end

        local Custom_Data = Mission_Structure_Data[Id];

        for _, Part in StructureObj.Parts do
            local At = (Part.CFrame * CFrame.new(0, -Part.Size.Y/2, 0))
            Service:Create(Type, At,  Custom_Data or Structure_Data.Default_Structure_Data)
        end
    end

    table.clear(Structure_Map_Data)
end

function Service:Create(Type: string, At: CFrame, StructureData: StructureData?)
    --
    local Rotation = math.atan2(At.LookVector.X, At.LookVector.Y)

    local DestructibleInstance = Destructible.new(Type, At.Position, Rotation)
    local UsedStructureData = StructureData or StructureDatabase:GetData(Type).Default_Structure_Data

    local DestructibleId = Service.__Total_Destructibles:extract()
    DestructibleInstance:Spawn(DestructibleId)

    DestructibleInstance.Destroyed:Connect(function(Caster: Types.ServerEnemyClass & AgentTypes.ServerAgentClass)
        Replicate(GameEnum.Replication.DestroyDestructible, DestructibleInstance:Compress(true))

        --
        if not UsedStructureData then return end
        Service:GiveRewards(UsedStructureData, Caster)
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

    if Data.SetValues then
        Service.StructureSetValuesEvent:Fire(Data.SetValues)
    end

    if Data.Drops then
        LootService:GiveLootToPlayer(Caster.__Player_Assigned, Data.Drops, true)
    end

end

function Service:Sync()
    -- add later :3
end

return Service