--


--
local MatchStats = {}
local Stats = {}

function MatchStats:AddToStat(Player: Player, StatName: string, Value: number)
    if not Stats[Player] then
        Stats[Player] = 0
    end

    Stats[Player] += Value
end

function MatchStats:GetPlayerStat(Player: Player, StatName: string)
    return (Stats[Player] or 0)
end

return MatchStats
