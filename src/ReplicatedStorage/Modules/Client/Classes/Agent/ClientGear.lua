local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local AgentTypes = require(Shared.Types.Agents)

--
local ClientGearStore = {}
ClientGearStore.__index = ClientGearStore

function ClientGearStore.new(): AgentTypes.ClientGearManager
    local self = setmetatable({}, ClientGearStore)

    return self
end

function ClientGearStore.Has(self: AgentTypes.ClientGearManager, objectName: string)
    
end

function ClientGearStore.AddItem(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.RemoveItem(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.AddGear(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.RemoveGear(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.GetAddedGearStat(self: AgentTypes.ClientGearManager, Stat: AgentTypes.Stat)
    return 0
end

return ClientGearStore
