local RunService = game:GetService("RunService")
local Ping = {
    __Val = {},
}

function Ping:Set(Player: Player, Time: number)
    Ping.__Val[Player] = Time
end

function Ping:Get(Player: Player)
    return (RunService:IsStudio() and Ping.__Val[Player] or Player:GetNetworkPing())
end

return Ping
