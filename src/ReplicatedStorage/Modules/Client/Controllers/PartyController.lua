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
        local PartyComponent = InterfaceController:GetComponent("Party")
        local NewComponent = InterfaceController:GetComponent("NewPartyComponent")

        if Type == GameEnum.PartyManaging.Create then
            local PlayerTeamData = Controller:GetTeamBuffer(ServerResponse :: CompressedParty, Player.UserId)
            if not PlayerTeamData then
                return
            end

            NewComponent:Set(true)
            NewComponent:SetPartyOwner(Player.UserId)
            NewComponent:AddPlayerToList((ServerResponse :: CompressedParty)[1])
            NewComponent:UpdateStages(StageData)
        elseif Type == GameEnum.PartyManaging.Join then
            NewComponent:Set(true)
            local List, Owner = Controller:GetPlayerListForParty(ServerResponse :: CompressedParty)

            NewComponent:SetPartyOwner(Owner)
            for Name, Data in List do
                NewComponent:AddPlayerToList(Name, Data, Name == Owner)
            end
        elseif Type == GameEnum.PartyManaging.PlayerJoined then
            local Data = ServerResponse :: CompressedParty
            NewComponent:AddPlayerToList(Data[1], Controller:BufferToTeamString(Data[2]), false)
        elseif Type == GameEnum.PartyManaging.PlayerLeft then
            local Data = ServerResponse :: CompressedParty
            NewComponent:RemovePlayerFromlist(Data[1])
        elseif Type == GameEnum.PartyManaging.Leave then
            NewComponent:Set(false)
            NewComponent:Clear()
        elseif Type == GameEnum.PartyManaging.Queue then
            --local Data = (ServerResponse :: {string})
            NewComponent:SetQueueing(true)
        elseif Type == GameEnum.PartyManaging.Failed then
            local ErrorMessage = ServerResponse :: string

            warn("Server received error:", ErrorMessage)
            NewComponent:SetQueueing(false)
        elseif Type == GameEnum.PartyManaging.SetReady then
            local ReadyCount = (ServerResponse :: {})[1]
            local PlayerIdReady = (ServerResponse :: {})[2]

            NewComponent:SetPlayerReady(ReadyCount, PlayerIdReady)
        elseif Type == GameEnum.PartyManaging.RemoveReady then
            NewComponent:RemoveReady()
        elseif Type == GameEnum.PartyManaging.ChangeTeam then
            local PlayerTeamData = ServerResponse :: CompressedParty

            --PartyComponent:UpdateTeam(PlayerTeamData[1], Controller:BufferToTeamString(PlayerTeamData[2] :: buffer))
        elseif Type == GameEnum.PartyManaging.ChangeStage then
            local PartyStageData = ServerResponse :: {string}

            NewComponent:UpdateStageInfo(PartyStageData[1])
        end
    end)
end

function Controller:GetPlayerListForParty(Compressed: CompressedParty)
    local List = {}

    print("Full list:", Compressed)

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
