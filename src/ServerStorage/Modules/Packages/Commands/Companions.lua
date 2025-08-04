local ServerStorage = game:GetService("ServerStorage")
local PlayerCompanionData = require(ServerStorage.Modules.Classes.Data.PlayerCompanionData)
return function(Caster: TextSource, Params: {})

    local Amount = tonumber(Params[1], 10) or 2

    for i = 1, Amount do
        local Class = PlayerCompanionData.randomize("Default")

        -- add them to data here
    end
end
