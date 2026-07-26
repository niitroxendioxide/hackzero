--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local Characters = require(Shared.Database.Characters)

--
local Party = {}
Party.__index = Party

function Party.new(Code: number, Owner: Types.PartyPlayer, MissionData: {}?): Types.PartyClass
    local self = setmetatable({} :: Types.PartyClass, Party)
    self.Code = Code

    self.__Players = {}
    self.__Owner = Owner:GetId()
    self.__Stage = "Mission/Unknown/None"
    self.__FriendsOnly = false
    self.__State = 1
    self.__Max_Players = 4
    self.__Player_Count = 1
    self.__Ready = {}
    self.__State_Name = "Idle"
    self.__Teams = {}
    self.__Companions = {}
    self.__Data = MissionData or {}

    return self
end

function Party.AddPlayer(self: Types.PartyClass, Player: Types.PartyPlayer): ()
    if self:HasPlayer(Player:GetId()) then
        return;
    end

    self:SetPlayerTeam(Player, {})

    table.insert(self.__Players, Player)
end

function Party.SetReady(self: Types.PartyClass, Player: Types.PartyPlayer)
    if table.find(self.__Ready, Player) then
        return
    end

    table.insert(self.__Ready, Player)
end

function Party.IsReady(self: Types.PartyClass)
    local ReadyCount = #self.__Ready

    return ReadyCount == #self.__Players
end

function Party.CancelReady(self: Types.PartyClass, Player: Types.PartyPlayer): boolean
    if self.__State == GameEnum.PartyStates.Queueing then
        return false
    end

    local Index = table.find(self.__Ready   , Player)

    if Index then
        table.remove(self.__Ready, Index)
    end

    return true
end

function Party.GetDifficulty(self: Types.PartyClass)
    local Data = self:GetData()
    if Data then
        if Data.Stage ~= nil then
            return Data.Stage.Difficulty
        else
            return Data.Difficulty or 'EASY'
        end
    end

    return 'EASY'
end

function Party.SwitchStage(self: Types.PartyClass, Type: string, Stage: string, Act: string)
    self.__Stage = Type..'/'..Stage..'/'..Act
end

function Party.SetData(self: Types.PartyClass, Data: {}?)
    self.__Data = Data
end

function Party.GetData(self: Types.PartyClass)
    return self.__Data
end

function Party.RemovePlayer(self: Types.PartyClass, PlayerToRemove: Types.PartyPlayer)
    for key, PartyPlayer in self.__Players do
        if PartyPlayer:GetId() == PlayerToRemove:GetId() then
            table.remove(self.__Players, key)
        end
    end

    self:SetPlayerTeam(PlayerToRemove, nil)
end

function Party.HasPlayer(self: Types.PartyClass, Id: number): (boolean)
    for _, Player in self.__Players do
        if Player:GetId() == Id then
            return true
        end
    end

    return false;
end

function Party.GetPlayers(self: Types.PartyClass)
    return self.__Players
end

function Party.GetRawPlayers(self: Types.PartyClass)
    local List = {}
    for _, PlayerObject in self.__Players do
        table.insert(List, PlayerObject.PlayerObject)
    end

    return List;
end

function Party.GetPlayerCount(self: Types.PartyClass): number
    return #self.__Players
end

function Party.GetState(self: Types.PartyClass): number
    return self.__State
end

function Party.GetMaxPlayers(self: Types.PartyClass): number
    return self.__Max_Players
end

function Party.GetStage(self: Types.PartyClass): (string)
    return self.__Stage
end

function Party.GetStagePlace(self: Types.PartyClass): (string)
    local Split = string.split(self.__Stage, "/")
    if Split[1] == 'ChaosControl' then
        Split[1] = 'Mission'
    end

    return Split[1]
end

function Party.SetState(self: Types.PartyClass, State: Types.PartyState): ()
    local StateName = GameEnum.KeyLookup(GameEnum.PartyStates, State)

    self.__State = State;
    self.__State_Name = StateName;
end

function Party.IsOwner(self: Types.PartyClass, Player: Types.PartyPlayer): ()
    return self.__Owner == Player:GetId()
end

function Party.GetDataTeam(self: Types.PartyClass, Player: Types.PartyPlayer)
    return {}
end

function Party.GetPlayerTeam(self: Types.PartyClass, Player: Types.PartyPlayer)
    return self.__Teams[Player:GetId()]
end

function Party.SetPlayerTeam(self: Types.PartyClass, Player: Types.PartyPlayer, Team: Types.PartyPlayerTeam): ()
    self.__Teams[Player:GetId()] = Team;
end

function Party.GetPlayerCompanion(self: Types.PartyClass, Player: Types.PartyPlayer)
    return self.__Companions[Player:GetId()]
end

function Party.SetPlayerCompanion(self: Types.PartyClass, Player: Types.PartyPlayer, CompanionId: string)
    self.__Companions[Player:GetId()] = CompanionId
end

function Party.GetSimplifiedTeam(self: Types.PartyClass, Player: Types.PartyPlayer): (string)
    local TeamName = "";

    for _, Character in self:GetPlayerTeam(Player) do
        TeamName = TeamName..Character.Name..", "
    end

    return TeamName;
end


function Party.Destroy(self: Types.PartyClass): ()

    for _, Player in self.__Players do
        self:RemovePlayer(Player)
    end

end

function Party.GetStateName(self: Types.PartyClass): string
    return self.__State_Name
end

function Party.GetPlayerCompressedTeam(self: Types.PartyClass, Player: Types.PartyPlayer)
    local Team = self:GetSimplifiedTeam(Player)
    local Split = string.split(Team :: string, ", ")

    local bufferTeam = buffer.create(3)
    for index, Name in Split do
        local CharacterId = Characters:GetIdForCharacter(Name)
        if not CharacterId then continue end

        buffer.writeu8(bufferTeam, index - 1, CharacterId)
    end

    return bufferTeam
end

function Party.Compress(self: Types.PartyClass): {}
    local Compressed = {}

    for _, Player in self:GetPlayers() do
        local Team = self:GetPlayerCompressedTeam(Player)

        table.insert(Compressed, Player:GetId())
        table.insert(Compressed, Team)
    end

    table.insert(Compressed, self.__Owner)

    return Compressed
end

return Party