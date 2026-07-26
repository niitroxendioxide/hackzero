local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Player = Players.LocalPlayer

local Types = require(Shared.Types)
local Places = require(Shared.Places)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Characters = require(Database.Characters)

--
local InterfaceController = require(ReplicatedStorage.Modules.Client.Controllers.InterfaceController)
local UIEffects = require(ReplicatedStorage.Modules.Client.Utility.UIEffects)


type CompressedParty = {number | buffer}
--
local Controller = {
    __Current_Party = nil,
}

function Controller:Init()
    if not Places:IsInPlace("Lobby") then
        return;
    end

    Network:On("Party", function(Type: number, ServerResponse: CompressedParty | string | {any}, StageData: {}): ()
        --local PartyComponent = InterfaceController:GetComponent("Party")
        local NewComponent = InterfaceController:GetComponent("NewPartyComponent")

        if Type == GameEnum.PartyManaging.Create then
            local PlayerTeamData = Controller:GetTeamBuffer(ServerResponse :: CompressedParty, Player.UserId)
            if not PlayerTeamData then
                return
            end

            NewComponent:Set(true)
            NewComponent:SetPartyOwner(Player.UserId)
            NewComponent:AddPlayerToList(Player.UserId, 1)
        
            Controller:FilterWithStageData(StageData)

            StageData.Rewards = StageData.Rewards or {}
            NewComponent:ShowRewards(StageData.Rewards)

        elseif Type == GameEnum.PartyManaging.Join then
            NewComponent:Set(true)

            local PlayerBuffers = ServerResponse :: CompressedParty
            local List, Owner = Controller:GetPlayerListForParty(PlayerBuffers)

            Controller:FilterWithStageData(StageData)
            NewComponent:SetPartyOwner(Owner)
            for PlayerId in List do
                NewComponent:AddPlayerToList(PlayerId, StageData[3])
            end

        elseif Type == GameEnum.PartyManaging.PlayerJoined then
            local Data = ServerResponse

            NewComponent:AddPlayerToList(Data[1], Data[2])

        elseif Type == GameEnum.PartyManaging.PlayerLeft then
            local Data = ServerResponse
            NewComponent:RemovePlayerFromList(Data[1], Data[2])

        elseif Type == GameEnum.PartyManaging.Leave then
            NewComponent:Clear()
            NewComponent:Set(false)

        elseif Type == GameEnum.PartyManaging.Queue then
            --local Data = (ServerResponse :: {string})
            NewComponent:SetQueueing(true)

        elseif Type == GameEnum.PartyManaging.Failed then
            local ErrorMessage = ServerResponse :: string

            UIEffects:DisplayErrorMessage("Server error:" .. ErrorMessage, 3)

            NewComponent:SetQueueing(false)

        elseif Type == GameEnum.PartyManaging.SetReady then
            local ReadyCount = (ServerResponse :: {})[1]
            local PlayerIdReady = (ServerResponse :: {})[2]

            NewComponent:SetPlayerReady(ReadyCount, PlayerIdReady)

        elseif Type == GameEnum.PartyManaging.RemoveReady then
            NewComponent:RemoveReady()

        elseif Type == GameEnum.PartyManaging.ChangeTeam then
            --local PlayerTeamData = ServerResponse :: CompressedParty

            --PartyComponent:UpdateTeam(PlayerTeamData[1], Controller:BufferToTeamString(PlayerTeamData[2] :: buffer))

        elseif Type == GameEnum.PartyManaging.ChangeStage then
            local PartyStageData = ServerResponse :: {string}

            NewComponent:UpdateStageInfo(PartyStageData[1])
        end
    end)
end

function Controller:FilterWithStageData(ServerPartyData: { [string]: any })
    local Stage = ServerPartyData[1]
    local Data = ServerPartyData[2]
    local NewComponent = InterfaceController:GetComponent("NewPartyComponent")

    if Data.ChaosControlData then
        NewComponent:SetMode('ChaosControl', Data)
    elseif Data.Training then
        NewComponent:SetMode('Expedition')
        NewComponent:UpdateStageInfo('Expedition/Training/Intro')
    elseif Data.MissionId then
        NewComponent:SetMode('Mission')
        NewComponent:UpdateStageInfo(Stage)
    else
        NewComponent:SetMode('Mission')
        NewComponent:UpdateStageInfo(Stage)
        NewComponent:UpdateMissions(Data or {})
    end
end

function Controller:GetPlayerListForParty(Compressed: CompressedParty)
    local List = {}

    for i = 1, #Compressed, 2 do
        if i == #Compressed then
            break
        end

        local Name = Compressed[i]
        local Team = Controller:BufferToTeamString(Compressed[i + 1] :: buffer)

        List[Name] = Team
    end

    return List, List[#List]
end

function Controller:GetTeamBuffer(Data: {number | buffer}, Id: number)
    local index = table.find(Data, Id)
    if not index then
        return
    end

    return Data[index + 1]
end

function Controller:BufferToTeamString(bufferObject: buffer): string
    local TeamText = "";

    for i = 0, 2 do
        local Character = Characters:GetCharacterFromId(buffer.readu8(bufferObject, i))

        if Character then
            TeamText = TeamText..Character..", "
        end
    end

    if #TeamText < 1 then
        TeamText = "[Empty Team]  "
    end

    return TeamText:sub(1, #TeamText-2)
end

function Controller:JoinQueue(Party: Types.PartyClass)
    Controller.__Current_Party = Party;
end

return Controller
