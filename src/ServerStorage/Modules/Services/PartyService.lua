local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local Network = require(Shared.Network)

local Service = {}

function Service:Init()
    Network.new("Party", "Event")
    Network:On("Party", Service.OnPartyEvent)

    Service:FetchParties()
end

function Service.OnPartyEvent(_Player: Player)

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
