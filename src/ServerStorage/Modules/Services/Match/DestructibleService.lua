-- Called by the match service so it's technically a library but whatever
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local AgentTypes = require(Shared.Types.Agents)
local StructureList = require(ServerStorage.Modules.Libraries.StructureList)
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

function Service:SetupStage()
    task.spawn(function()
        while true do
            if #StructureList:GetAll() < 3 then
                local X = math.random(-50, 50)
                local Z = math.random(-50, 50)
                local At = Vector3.new(-114.594 + X, 1.499, 379.083 + Z)

                Service:Create('Crystals', At, {
                    Effects = {
                        {
                            Type = 'Attack',
                            Value = '20%',
                            Time = 3,
                        }
                    },
                    Other = {Energy = 10},
                })
            end

            task.wait(2.5)
        end
    end)
end

function Service:Create(Type: string, At: Vector3, StructureData: StructureData?)
    --
    local Crystals = Destructible.new(Type, At)

    local CrystalId = Service.__Total_Destructibles:extract()
    Crystals:Spawn(CrystalId)

    Crystals.Destroyed:Connect(function(Caster: Types.ServerEnemyClass & AgentTypes.ServerAgentClass)
        Replicate(GameEnum.Replication.DestroyDestructible, Crystals:Compress(true))

        --
        if not StructureData then return end
        Service:GiveRewards(StructureData, Caster)
    end)

    local Objbuffer = Crystals:Compress()
    Replicate(GameEnum.Replication.CreateDestructible, Objbuffer)
end

function Service:GiveRewards(Data: StructureData, Caster: Types.ServerEnemyClass & AgentTypes.ServerAgentClass)
    local Player: Player? = Caster.__Player_Assigned

    if Data.Other then
        if Data.Other.Energy then
            Caster:GiveEnergy(Data.Other.Energy)
        end
    end

    -- do other stuff here !
    if Data.Effects then
        for _, Effect in Data.Effects do
            Caster:AddEffect(Effect)
        end
    end
end

function Service:Sync()
    -- add later :3
end

return Service