local ServerStorage = game:GetService("ServerStorage")
local EnemyService = require(ServerStorage.Modules.Services.Combat.EnemyService)

--
return function(Caster: TextSource, Parameters: {string})
    local Tag = Parameters[1]
    if #Tag <= 1 then
        Tag = nil
    end

    EnemyService:KillAll(Tag)
end
