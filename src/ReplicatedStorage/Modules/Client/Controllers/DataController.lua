--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local ArtifactDatabase = require(Shared.Database.Artifacts)
local CharacterDatabase = require(Shared.Database.Characters)
local LocalData = require(Client.Libraries.LocalData)
local InterfaceController = require(Client.Controllers.InterfaceController)

--
local function BufferTableToArtifact(Table: {})
    local Id, BufferObj = Table[1] :: string, Table[2] :: buffer
    local Equipped = buffer.readu8(BufferObj, 4)

    local MainStatKey = GameEnum.KeyLookup(GameEnum.MainStats, buffer.readu8(BufferObj, 5))
    local MainStatValue = buffer.readu8(BufferObj, 6)

    local ArtifactData: Types.PlayerArtifactData = {
        Id = Id,
        Name = ArtifactDatabase:GetFromId(buffer.readu8(BufferObj, 0)),
        Level = buffer.readu8(BufferObj, 1),
        Slot = buffer.readu8(BufferObj, 2),
        Tier = buffer.readu8(BufferObj, 3),
        Equipped = if Equipped == 0 then nil else CharacterDatabase:GetCharacterFromId(Equipped),
        Stats = {
            Main_Stat = {[MainStatKey] = MainStatValue},
            Sub_Stats = {},
        },
    }

    -- edit the substats
    local SubStats = {}
    for i = 7, 13, 2 do
        local Key = buffer.readu8(BufferObj, i)
        local Count = buffer.readu8(BufferObj, i + 1)
        local SubStatName = GameEnum.KeyLookup(GameEnum.SubStats, Key)

        -- Means there's no more substats
        if SubStatName == nil then
            break
        end

        SubStats[SubStatName] = Count
    end

    ArtifactData.Stats.Sub_Stats = SubStats

    return ArtifactData
end

--
local Controller = {}

function Controller:Init()

    Network:On("ItemData", function(Type: number, Payload: {}): ()
        if Type == GameEnum.ItemDataEvent.GetAllArtifacts then
            Controller:ConvertArtifacts(Payload)
        end
    end)

    Network:On("UpdateAgent", function(Type: number, Payload: {}): ()
        if Type == GameEnum.AgentEvent.UpdateArtifactSlot then
            Controller:UpdateArtifactState(Payload)
        end
    end)
end

function Controller:UpdateArtifactState(Payload: {number | {}})
    local UI = InterfaceController:GetComponent("AgentMenu")
    local Type = Payload[1]
    local Artifact = BufferTableToArtifact(Payload[2] :: {})
    local Agent = Payload[3]

    LocalData:EditArtifact(Artifact)
    UI:UpdateArtifact(Artifact)

    if Type == GameEnum.ArtifactEvent.Remove then
        UI:UpdateSlotInfo(Agent, Artifact.Slot, nil)

        return
    end

    UI:UpdateSlotInfo(Agent, Artifact.Slot, Artifact)
end

function Controller:ConvertArtifacts(Payload: {})
    local AllArtifacts = {}

    for _, Artifact in Payload do
        local ArtifactObjectData = BufferTableToArtifact(Artifact)

        -- Save to the full list
        table.insert(AllArtifacts, ArtifactObjectData)
    end

    LocalData:SetArtifacts(AllArtifacts)
end

return Controller