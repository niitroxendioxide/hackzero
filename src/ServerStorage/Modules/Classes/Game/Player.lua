--


--
local PlayerClass = {}
PlayerClass.__index = PlayerClass

function PlayerClass.new(Player: Player, Team)
    local self = setmetatable({}, PlayerClass)
    self.__PlayerObject = Player
    self.__Designated_Id = 0
    self.__Team = Team

    return self
end

function PlayerClass.GetId(self)
    return self.__Designated_Id
end

return PlayerClass
