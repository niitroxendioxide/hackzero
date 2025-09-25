

-- UNUSED CLASS, BUT CONCEPT IN CASE I DON'T REWRITE SERVERAGENT
local PlayerAgentClass = {}

function PlayerAgentClass.Create(...)
    local self = setmetatable({}, {})
    self.__Agent = nil; -- put the agent here?    

    return self
end

function PlayerAgentClass.PivotTo(self, At: CFrame)
    self.__Agent:PivotTo(At);

    -- Replicator:PivotTo(self.__Agent, At);
end

return PlayerAgentClass