--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared

local settings = require(ServerStorage.Modules[".testenv"].settings)
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

local Mock = require(Shared.Utility.Mock)


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
    Teleport a specific player to a place

--]]
function TeleportIndividualPlayer(PlaceId: number, Player: Player, Data: {}?): boolean
    local CurrentAttempts = MAX_TELEPORT_ATTEMPTS

    if Service.__Queue[Player] then
        return false
    end

    Service.__Queue[Player] = true

    repeat
        local Success, Error = pcall(function()
            TeleportService:Teleport(PlaceId, Player, Data)
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

    --
    Service.__Queue[Player] = false

    return true;
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

            if Code == nil then
                TeleportService:TeleportAsync(PlaceId, Players)
            else
                TeleportService:TeleportToPrivateServer(PlaceId, Code, Players, nil, Data)
            end
            
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

function Service:TeleportPlayer(Player: Player, Place: string): (boolean, string)
    local PlaceId = Places:GetId(Place)
    if not PlaceId then
        return false, "Invalid place id"
    end

    local Success = TeleportIndividualPlayer(PlaceId, Player, {})
    if not Success then
        return false, "Error teleporting player"
    end

    return true, ''
end

function Service:TeleportGroup(Stage: string, Party: Types.PartyClass, Data: {}): (boolean, string?)
    if Service.__Reserving[Party.Code] then
        return false, "Party is already teleporting"
    end

    Service.__Reserving[Party.Code] = true

    -- Logic checks
    local PartyStage = string.split(Party:GetStage(), '/')
    local TeleportData = {
        Mission = {
            Type = PartyStage[1],
            Stage = PartyStage[2],
            Act = PartyStage[3],
        },

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

    Service.__Reserving[Party.Code] = nil

    if not Success then
        return false, "Error when teleporting"
    end

    return true
end

function Service:ReturnToLobby(Group: {Player}): (boolean, string?)
    if Service.__Reserving[game.JobId] then
        return false, "Already teleporting back to lobby"
    end

    Service.__Reserving[game.JobId] = true

    -- Requests
    local Id = Places:GetId('Lobby')
    --local Reserved = ReserveServerForPlace(Id)
    local Success = TeleportPlayerGroupAttempt(Id, nil, Group, {})

    --print(Reserved, Success, Id, 'Lobby')

    Service.__Reserving[game.JobId] = nil

    if not Success then
        return false, "Error when teleporting"
    end

    return true
end

function Service:RepeatStage(): (boolean, string?)
    if Service.__Reserving[game.JobId] then
        return false, "Already teleporting to a place"
    end

    Service.__Reserving[game.JobId] = true

    -- Requests
    local Group = Players:GetPlayers()
    local Data = Group[1]:GetJoinData().TeleportData
    if not Data then
        return false, "Invalid data, place is not a mission."
    end


    -- TODO: VERIFY THAT THIS IS IN FACT A REPEATABLE QUEST. DON'T WANT PEOPLE BYPASSING THIS

    --
    local Id = Places:GetId('Mission')
    local Reserved = ReserveServerForPlace(Id)
    local Success = TeleportPlayerGroupAttempt(Id, Reserved, Group, Data)

    print(Reserved, Success, Id, 'Mission')

    Service.__Reserving[game.JobId] = nil

    if not Success then
        return false, "Error when teleporting"
    end

    return true
end


function Service:GetPlayerTeamFromData(Player: Player): {{Name: string, Level: number, IsBorrowed: boolean?}}
    local JoinData = Player:GetJoinData()

    if not JoinData.TeleportData then
        if not RunService:IsStudio() then
            Player:Kick("Cannot play match without a set team.")
        end

        local AgentsToTest = settings.TEST_AGENTS
        local Converted = {}
        for _, Name in AgentsToTest do
            table.insert(Converted, {
                Name = Name,
                Level = settings.BORROWED_AGENT_LEVEL,
                IsBorrowed = settings.USE_BORROW,
            })
        end

        return Converted
    end

    local PlayersTeleportData = JoinData.TeleportData.Players
    local PlayerData = PlayersTeleportData[tostring(Player.UserId)]

    TableUtil:printTable(PlayerData.Team)
    return PlayerData.Team
end

export type MatchData = {
    Mission: {
        Type: string,
        Stage: string,
        Act: string?,

        Data: {
            [string]: any,
        }
    }, 
    TotalPlayers: number
}

function Service:GetStageData(): MatchData
    if #Players:GetPlayers() < 1 and not RunService:IsRunMode() then
        Players.PlayerAdded:Wait()
    end

    local RandomPlayer = RunService:IsRunMode() and Mock or  Players:GetPlayers()[1] :: Player
    local JoinData = RunService:IsRunMode() and {} or  RandomPlayer:GetJoinData()
    local StageData = {} :: MatchData

    if not JoinData.TeleportData then
        StageData = {
            TotalPlayers = 1,
            Mission = {
                Type = settings.MISSION.TYPE,
                Stage = settings.MISSION.STAGE.Stage,
                Act = settings.MISSION.STAGE.Act,
                Data = settings.MISSION.DATA,
            },
        }
    else
        local TeleportData = JoinData.TeleportData
        local TotalPlayers = 0

        for _, Player in TeleportData.Players do
            TotalPlayers += 1
        end

        StageData.Mission = TeleportData.Mission
        StageData.TotalPlayers = TotalPlayers
    end

    if StageData.Mission.Type == 'ChaosControl' then
        local Data = StageData.Mission.Data;
        local MarkersList = {};

        local ChaosControlType = Data.ChaosControlType;
        if not Data.Enemies then
            return;
        end

        local TotalEnemies = 0;
        for Wave, WaveData in Data.Enemies do
            for _, EnemySpawnData in WaveData do
               TotalEnemies += EnemySpawnData.Amount; 
            end
        end

        MarkersList = {
            MainFight = {
                Type = 'Trigger',
                Data = {
                    Goal = {
                        KillEnemies = TotalEnemies,
                    },
                    Enemies = Data.Enemies,
                    Buffs = Data.EnemyBuffs,
                    Finished = 'End',
                },
            }
        }

        StageData.Mission.Data.Markers = MarkersList;
    end

    return StageData
end

return Service