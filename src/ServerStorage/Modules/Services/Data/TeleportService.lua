--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

local Shared = ReplicatedStorage.Modules.Shared

local Places = require(Shared.Places)
local Types = require(Shared.Types)

--
local MAX_TELEPORT_ATTEMPTS = 10
local MAX_RESERVE_ATTEMPTS = 10
local Service = {
    __Queue = {},
    __Reserving = {},
}

-- Private functions

-- Teleport a specific person
function ReserveServerForPlace(PlaceId: number): number?
    local CurrentAttempts = MAX_RESERVE_ATTEMPTS
    local Code;

    repeat
        local Success, Error = pcall(function()
            Code = TeleportService:ReserveServer(PlaceId)
        end)

        if not Success then
            CurrentAttempts -= 1
            warn(Error)
        else
            break
        end

        task.wait(.25)
    until CurrentAttempts <= 0 or Success

    if CurrentAttempts <= 0 then
        return;
    end

    return Code;
end

function TeleportPlayerGroupAttempt(PlaceId: number, Code: number, Players: {Player}, Data: {})
    local CurrentAttempts = MAX_TELEPORT_ATTEMPTS

    for _, Player in Players do
        if Service.__Queue[Player] then
            return false
        end

        Service.__Queue[Player] = true
    end

    repeat
        local Success, Error = pcall(function()
            TeleportService:TeleportToPrivateServer(PlaceId, Code, Players, nil, Data)
        end)

        if not Success then
            CurrentAttempts -= 1
            warn("Error when teleporting players", Error)
        else
            break
        end

        task.wait(.25)
    until CurrentAttempts <= 0 or Success

    if CurrentAttempts <= 0 then
        warn("Teleport failed")

        return false
    end

    for _, Player in Players do
        Service.__Queue[Player] = nil
    end

    return true;
end


--
function Service:Init()
    
end

function Service:TeleportPlayer()
    
end

function Service:TeleportGroup(Stage: string, Party: Types.PartyClass, Data: {})
    if Service.__Reserving[Party.Code] then
        return
    end

    Service.__Reserving[Party.Code] = true

    --
    local Id = Places:GetId(Stage)
    local Reserved = ReserveServerForPlace(Id)
    local Success = TeleportPlayerGroupAttempt(Id, Reserved, Party:GetRawPlayers(), {})

    print(Reserved, Success, Id, Stage)

    if not Success then
        warn("Wateflip")
    end

    Service.__Reserving[Party.Code] = nil
    --
end

return Service