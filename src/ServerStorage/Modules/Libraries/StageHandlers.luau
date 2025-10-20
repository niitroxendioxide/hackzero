local ServerStorage = game:GetService("ServerStorage")

local Components = ServerStorage.Modules.Components
local Handlers = {
    __Stages = {},
}


function Handlers:Init()
    for _, Stage in Components.Maps:GetChildren() do
        local StageName = Stage.Name
        Handlers.__Stages[StageName] = {}

        for _, Act in Stage:GetChildren() do
            local ActName = Act.Name
            local Valid, Handler = pcall(require, Act)
            if not Valid then
                warn('Invalid handler for stage: ' .. StageName .. ' act: ' .. ActName)
                continue
            end

            Handlers.__Stages[StageName][ActName] = Handler
        end
        
    end
end

function Handlers:Get(Stage: string, Act: string)
    if Handlers.__Stages[Stage] == nil then
        return nil
    end

    return Handlers.__Stages[Stage][Act]
end


return Handlers