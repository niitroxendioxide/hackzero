--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Modules.Shared

local Places = require(Shared.Places)
local Types = require(Shared.Types)
local TableUtil = require(Shared.Utility.Table)

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

--[[
Teleport a group of people
@param PlaceId The place Id of the world to telepor them to
@param Code The reserved server to teleport the players to
@param Players The list of players to teleport to the reserved server
@param Data The data to be sent to the reserved server with the players (in order to begin action in said servers)

@return `boolean` Whether or not the teleport was succesful
]]
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
    if Places:CanFight() then
        print("Initialize match here (Call MatchService.lua)")
    end
end

function Service:TeleportPlayer()
    return Types.NOT_IMPLEMENTED_ERROR()
end

function Service:TeleportGroup(Stage: string, Party: Types.PartyClass, Data: {}): (boolean, string?)
    if Service.__Reserving[Party.Code] then
        return false, "Party is already teleporting"
    end

    Service.__Reserving[Party.Code] = true

    -- Logic checks
    local TeleportData = {
        Stage = Party:GetStage(),
        Players = {},
    }

    for _, Player: Types.PartyPlayer in Party:GetPlayers() do
        local Team = Party:GetPlayerTeam(Player)

        if Team == nil or #Team < 1 then
            return false, "Player {"..Player.PlayerObject.Name.."} team is empty"
        end

        TeleportData.Players[Player:GetId()] = {
            Team = Team,
        }
    end


    -- Requests
    local Id = Places:GetId(Stage)
    local Reserved = ReserveServerForPlace(Id)
    local Success = TeleportPlayerGroupAttempt(Id, Reserved, Party:GetRawPlayers(), TeleportData)

    print(Reserved, Success, Id, Stage)

    Service.__Reserving[Party.Code] = nil

    if not Success then
        return false, "Error when teleporting"
    end

    return true
end

function Service:GetPlayerTeamFromData(Player: Player): {string}
    local JoinData = Player:GetJoinData()

    if not JoinData.TeleportData then
        if not RunService:IsStudio() then
            Player:Kick("Cannot play match without a set team.")
        end

        return {"Goku", "Asta", "Yuno"}
    end

    local PlayersTeleportData = JoinData.TeleportData.Players
    local PlayerData = PlayersTeleportData[tostring(Player.UserId)]


    TableUtil:printTable(PlayerData.Team)
    return PlayerData.Team
end

return Service