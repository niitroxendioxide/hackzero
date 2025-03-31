local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = Shared.Classes

local Types = require(Shared.Types)
local Network = require(Shared.Network)
local PartyPlayerClass = require(Classes.Party.PartyPlayer)

local Service = {
    __Player_Classes = {},
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

function Service.OnPartyEvent(Player: Player)
    if not Service.__Player_Classes[Player]  then
        Service.__Player_Classes[Player] = PartyPlayerClass.new(Player, 1, {})
    end


end

function Service:FetchParties(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:JoinParty(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:LeaveParty(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:DeleteParty(): ()
    return Types.NOT_IMPLEMENTED_ERROR()
end

return Service
