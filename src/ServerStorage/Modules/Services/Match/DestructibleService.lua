-- Called by the match service so it's technically a library but whatever
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local Heap = require(Shared.Utility.Heap)
local Network = require(Shared.Network)
local Destructible = require(Modules.Classes.Game.Destructible)
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
        for i = 1, 3 do
            local X = math.random(-50, 50)
            local Z = math.random(-50, 50)
            local At = Vector3.new(-114.594 + X, 1.499, 379.083 + Z)

            Service:Create('Crystals', At)

            task.wait(2.5)
        end
    end)
end

function Service:Create(Type: string, At: Vector3)
    local Crystals = Destructible.new(Type, At)

    Crystals:Spawn(Service.__Total_Destructibles:extract())

    local Objbuffer = Crystals:Compress()
    Replicate(GameEnum.Replication.CreateDestructible, Objbuffer)
end

function Service:Sync()
    -- add later :3
end

return Service