local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared
local AgentTypes = require(Shared.Types.Agents)

local Fetcher = {
    __Cache = {}
}

function Fetcher:Init()
    for _, Source in Classes.Items.Artifacts:GetChildren() do
        local Success, ArtifactClass = pcall(require, Source)

        if Success then
            local ImplLess = string.gsub(Source.Name, "Implementation", "")
            Fetcher.__Cache[ImplLess] = ArtifactClass;
        else
            warn("Error loading source for artifact:", Source.Name)
        end
    end
end

function Fetcher:Get(Name: string): AgentTypes.AgentArtifactClass
    return Fetcher.__Cache[Name]
end

function Fetcher:ExtendFrom(Name: string, Level: number): AgentTypes.AgentArtifactClass
    local Class = Fetcher:Get(Name)
    if not Class then
        return Fetcher:Get("TEMPLATE");
    end

    return Class:Extend(Level)
end

return Fetcher

