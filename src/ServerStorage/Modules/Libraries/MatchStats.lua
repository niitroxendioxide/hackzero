--


--
local MatchStats = {}
local Stats = {}

function MatchStats:AddToStat(Player: Player, StatName: string, Value: number)
    if not Stats[Player] then
        Stats[Player] = {}
    end

    Stats[Player][StatName] = (Stats[Player][StatName] or 0) + Value
end

function MatchStats:GetPlayerStat(Player: Player, StatName: string)
    return (Stats[Player][StatName] or 0)
end

function MatchStats:GetAllPlayerStats(Player: Player)
    return Stats[Player]
end

return MatchStats
