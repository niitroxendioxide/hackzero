local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = Shared.Classes

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local PartyPlayerClass = require(Classes.Party.PartyPlayer)
local PartyClass = require(Classes.Party.Party)

local Service = {
    __Player_Classes = {},
    __Parties = {}
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

function Service.OnPartyEvent(Player: Player, Type: number)
    print("Server received party request:", GameEnum.KeyLookup(GameEnum.PartyManaging, Type))

    if Type == GameEnum.PartyManaging.Create then
        local Code = HttpService:GenerateGUID(false):sub(1, 7)
        local NewParty = PartyClass.new(Code)

        Service.__Parties[Code] = NewParty
        Service:JoinParty(Player, Code)

        --
        Network:Fire("Party", Player, GameEnum.PartyManaging.Create, NewParty)
    end
end

function Service:FetchParties(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:JoinParty(Player: Player, Code: any): ()
    local PlayerClass = Service:GetClass(Player)
    local Party = Service:GetParty(Code)
    if not Party then
        return
    end

    Player:AddTag("InParty")

    Party:AddPlayer(PlayerClass)
end

function Service:LeaveParty(Player: Player): ()
    Player:RemoveTag("InParty")
end

function Service:DeleteParty(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:GetParty(Code: any): Types.PartyClass
    return Service.__Parties[Code]
end

function Service:GetClass(Player: Player): Types.PartyPlayer
    if not Service.__Player_Classes[Player]  then
        Service.__Player_Classes[Player] = PartyPlayerClass.new(Player, 1, {})
    end

    return Service.__Player_Classes[Player];
end

return Service
