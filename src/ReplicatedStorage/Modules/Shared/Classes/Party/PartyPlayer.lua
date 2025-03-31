--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local PartyPlayer = {}
PartyPlayer.__index = PartyPlayer

function PartyPlayer.new(Player: Player, Level: number, Team: Types.PartyPlayerTeam)
    local self = setmetatable({}, PartyPlayer)
    self.PlayerObject = Player
    self.Level = Level
    self.Team = Team
end

function PartyPlayer.GetId(self: Types.PartyPlayer)
    return self.Player.UserId
end

function PartyPlayer.GetSimplifiedTeam(self: Types.PartyPlayer): (string)
    local TeamName = "";

    for _, Character in self.Team do
        TeamName = TeamName..Character.Name..", "
    end

    return TeamName;
end

return PartyPlayer
