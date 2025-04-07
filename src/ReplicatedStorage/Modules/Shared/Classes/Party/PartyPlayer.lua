--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types)

--
local PartyPlayer = {}
PartyPlayer.__index = PartyPlayer

function PartyPlayer.new(Player: Player, Level: number)
    local self = setmetatable({}, PartyPlayer)
    self.PlayerObject = Player
    self.Level = Level

    return self
end

function PartyPlayer.GetId(self: Types.PartyPlayer)
    return self.PlayerObject.UserId
end

return PartyPlayer
