local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Shared.Classes
local DataModules = Modules.Services.Data

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local PartyPlayerClass = require(Classes.Party.PartyPlayer)
local PartyClass = require(Classes.Party.Party)
local Notifications = require(Modules.Packages.Notifications)

local DataService = require(DataModules.DataService)
local TeleportService = require(DataModules.TeleportService)

--
local Service = {
    __Player_Classes = {},
    __Parties = {} :: {[string]: Types.PartyClass},
    __Player_Party = {},
    __Invites = {},
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
    elseif Type == GameEnum.PartyManaging.Join then
        local Request = {...}
        local Party = Service:GetParty(Request[1])

        if not Party then
            return
        end

        Service:JoinParty(Player, Request[1])

        --
        Network:Fire("Party", Player, GameEnum.PartyManaging.Join, Party:Compress())
    elseif Type == GameEnum.PartyManaging.Leave then
        local Code = Service:GetCode(Player)
        local Party = Service:GetParty(Code)
        Service:LeaveParty(Player)

        Network:Fire("Party", Player, GameEnum.PartyManaging.Leave)

        local Count = 0;
        for _, PartyUser in Party:GetRawPlayers() do
            if PartyUser == Player then continue end

            Count+=1;
            local Sent = {Player.UserId}

            Network:Fire("Party", PartyUser, GameEnum.PartyManaging.PlayerLeft, Sent)
        end

        if Count <= 0 then
            Service:DeleteParty(Code)
        end
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
    elseif Type == GameEnum.PartyManaging.Invite then
        local Data = {...}
        local PlayerName = Data[1]
        local Code = Service:GetCode(Player)
        local InvitedPlayer = Players:FindFirstChild(PlayerName)
        if not InvitedPlayer then
            return
        end

        Service:InvitePlayer(InvitedPlayer, Code)
    elseif Type == GameEnum.PartyManaging.AcceptInvite then
        local Data = {...}

        if not Service:HasInviteFor(Player, Data[1]) then return end

        local PlayerClass = Service:GetClass(Player)
        Service:JoinParty(Player, Data[1])
        Service:RemoveInvite(Player, Data[1])
        local Party = Service:GetParty(Data[1])

        Network:Fire("Party", Player, GameEnum.PartyManaging.Join, Party:Compress())

        for _, PartyUser in Party:GetRawPlayers() do
            if PartyUser == Player then continue end

            local Sent = {Player.UserId, Party:GetPlayerCompressedTeam(PlayerClass)}

            Network:Fire("Party", PartyUser, GameEnum.PartyManaging.PlayerJoined, Sent)
        end
    elseif Type == GameEnum.PartyManaging.RejectInvite then
        local Data = {...}

        if Service:HasInviteFor(Player, Data[1]) then
            Service:RemoveInvite(Player, Data[1])
        end
    end
end

function Service:RemoveInvite(Player: Player, Code: string)
    for key, Invite in Service.__Invites[Player] do
        if Invite[1] == Code then
            table.remove(Service.__Invites[Player], key)
        end
    end
end

function Service:InvitePlayer(Player: Player, Code: string)
    local Party = Service:GetParty(Code)
    if not Party then return end

    local Data = {
        Code,
        Players:GetPlayerByUserId(Party.__Owner),
        15,
    }

    if Service:HasInviteFor(Player, Code) then return end

    table.insert(Service.__Invites[Player], Data)

    Notifications:Send(Player, GameEnum.NotificationTypes.PartyInvite, Data)
end
function Service:HasInviteFor(Player: Player, Code: string): boolean
    if not Service.__Invites[Player] then
        Service.__Invites[Player] = {}
        return false
    end

    for _, Invite in Service.__Invites[Player] do
        if Invite[1] == Code then
            return true
        end
    end

    return false
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

function Service:DeleteParty(Code: string): ()
    Service.__Parties[Code]:Destroy()

    Service.__Parties[Code] = nil
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

    if not Party then return; end
    Party:SetPlayerTeam(PlayerClass, Agents)
end

return Service