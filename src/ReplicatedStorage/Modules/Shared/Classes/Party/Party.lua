--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local Characters = require(Shared.Database.Characters)

--
local Party = {}
Party.__index = Party

function Party.new(Code: number, Owner: Types.PartyPlayer): Types.PartyClass
    local self = setmetatable({} :: Types.PartyClass, Party)
    self.Code = Code

    self.__Players = {}
    self.__Owner = Owner:GetId()
    self.__Stage = "Mission/Earth/Intro"
    self.__FriendsOnly = false
    self.__State = 1
    self.__Max_Players = 4
    self.__State_Name = "Idle"
    self.__Teams = {}

    return self
end

function Party.AddPlayer(self: Types.PartyClass, Player: Types.PartyPlayer): ()
    if self:HasPlayer(Player:GetId()) then
        return;
    end

    self:SetPlayerTeam(Player, {})

    table.insert(self.__Players, Player)
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

function Party.GetMaxPlayers(self: Types.PartyClass): number
    return self.__Max_Players
end

function Party.GetStage(self: Types.PartyClass): (string)
    return self.__Stage
end

function Party.GetStagePlace(self: Types.PartyClass): (string)
    local Split = string.split(self.__Stage, "/")

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

function Party.GetPlayerTeam(self: Types.PartyClass, Player: Types.PartyPlayer)
    return self.__Teams[Player:GetId()]
end

function Party.GetDataTeam(self: Types.PartyClass, Player: Types.PartyPlayer)
    return {}
end

function Party.SetPlayerTeam(self: Types.PartyClass, Player: Types.PartyPlayer, Team: Types.PartyPlayerTeam): ()
    self.__Teams[Player:GetId()] = Team;
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
    local Split = string.split(Team, ", ")

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

    return Compressed
end

return Party