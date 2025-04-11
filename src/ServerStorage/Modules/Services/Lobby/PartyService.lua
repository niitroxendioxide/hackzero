local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Shared.Classes
local Data = Modules.Services.Data

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local PartyPlayerClass = require(Classes.Party.PartyPlayer)
local PartyClass = require(Classes.Party.Party)

local DataService = require(Data.DataService)
local TeleportService = require(Data.TeleportService)

--
local Service = {
    __Player_Classes = {},
    __Parties = {} :: {[string]: Types.PartyClass},
    __Player_Party = {},
}

--
function Service:Init()
    Network.new("Party", "Event")
    Network:On("Party", Service.OnPartyEvent)
end

function Service:ClearPlayer(Player: Player)
    if Service.__Player_Classes[Player] then
        Service.__Player_Classes[Player] = nil
    end
end

function Service.OnPartyEvent(Player: Player, Type: number, ...)
    --print("Server received party request:", GameEnum.KeyLookup(GameEnum.PartyManaging, Type))

    if Type == GameEnum.PartyManaging.Create then
        local NewParty = Service:CreateParty(Player)

        --
        Network:Fire("Party", Player, GameEnum.PartyManaging.Create, NewParty:Compress())
    elseif Type == GameEnum.PartyManaging.Leave then
        Service:LeaveParty(Player)

        Network:Fire("Party", Player, GameEnum.PartyManaging.Leave)
    elseif Type == GameEnum.PartyManaging.Start then
        local Result, Message = Service:Start(Player)

        if not Result then
            Network:Fire("Party", Player, GameEnum.PartyManaging.Failed, Message)
        end
    elseif Type == GameEnum.PartyManaging.ChangeTeam then
        local Data = {...}

        Service:ChangeTeam(Player, Data[1])

        --
        local Code = Service:GetCode(Player)
        local PlayerClass = Service:GetClass(Player)
        local Party = Service:GetParty(Code)

        for _, Player in Party:GetRawPlayers() do
            local Team = Party:GetPlayerCompressedTeam(PlayerClass)

            Network:Fire("Party", Player, GameEnum.PartyManaging.ChangeTeam, {Player.UserId, Team})
        end
    elseif Type == GameEnum.FetchRequests.Parties then
        Network:Fire("DataFetchRequest", Player, GameEnum.FetchRequests.Parties, Service:FetchParties())
    end
end

function Service:GetCode(Player: Player)
    return Service.__Player_Party[Player]
end

function Service:FetchParties(): ()
    local List = {}

    for Code, Party in Service.__Parties do
        local Max = Party:GetMaxPlayers()
        local PlayerCount = 0;

        local Level = 0;
        for _, Player in Party:GetPlayers() do
            PlayerCount += 1

            Level += Player.Level
        end

        table.insert(List, {Code, Party.__Owner, PlayerCount, Max, Level / PlayerCount})
    end

    return List
end

function Service:CreateParty(Player: Player)
    local Code = HttpService:GenerateGUID(false):sub(1, 7)
    local NewParty = PartyClass.new(Code,Service:GetClass(Player))

    Service.__Parties[Code] = NewParty
    Service:JoinParty(Player, Code)

    return NewParty
end

function Service:JoinParty(Player: Player, Code: any): ()
    local PlayerClass = Service:GetClass(Player)
    local Party = Service:GetParty(Code)
    if not Party then
        return
    end

    Service.__Player_Party[Player] = Code
    Player:AddTag("InParty")

    Party:AddPlayer(PlayerClass)
end

function Service:LeaveParty(Player: Player): ()
    local PlayerClass = Service:GetClass(Player)
    local Party = Service:GetParty(Service:GetCode(Player))

    Player:RemoveTag("InParty")

    if not Party or not PlayerClass then
        return
    end

    --
    Service.__Player_Party[Player] = nil
    Party:RemovePlayer(PlayerClass)
end

function Service:DeleteParty(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:Start(Player: Player): boolean
    local PlayerClass = Service:GetClass(Player)
    local Party = Service:GetParty(Service:GetCode(Player))

    if not Party:IsOwner(PlayerClass) then
        return false
    end

    Party:SetState(GameEnum.PartyStates.Teleporting)

    GameEnum:ValueNameFrom("PartyStates", 1)
    return TeleportService:TeleportGroup(Party:GetStagePlace(), Party, {})
end

function Service:GetParty(Code: any): Types.PartyClass
    return Service.__Parties[Code]
end

function Service:GetClass(Player: Player): Types.PartyPlayer
    if not Service.__Player_Classes[Player]  then
        Service.__Player_Classes[Player] = PartyPlayerClass.new(Player, 1)
    end

    return Service.__Player_Classes[Player];
end

function Service:ChangeTeam(Player: Player, Names: {string}): ()
    local PlayerClass = Service:GetClass(Player)
    local Party = Service:GetParty(Service:GetCode(Player))
    if not PlayerClass then
        return
    end

    --
    local Agents = {}

    for _, Name in Names do
        local Agent = DataService:GetAgent(Player, Name)

        table.insert(Agents, Agent)
    end

    Party:SetPlayerTeam(PlayerClass, Agents)
end

return Service
