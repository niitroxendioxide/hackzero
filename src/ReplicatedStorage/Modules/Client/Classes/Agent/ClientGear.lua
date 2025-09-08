local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local GearDatabase = require(Shared.Database.Gears)
local AgentTypes = require(Shared.Types.Agents)

--
local ClientGearStore = {}
ClientGearStore.__index = ClientGearStore

function ClientGearStore.new(): AgentTypes.ClientGearManager
    local self = setmetatable({}, ClientGearStore)
    self.__Gears = {}

    return self
end

function ClientGearStore.Has(self: AgentTypes.ClientGearManager, objectName: string)
    
end

function ClientGearStore.AddItem(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.RemoveItem(self: AgentTypes.ClientGearManager, object)
    
end

function ClientGearStore.AddGear(self: AgentTypes.ClientGearManager, GearName: string)
    
    local GearData = GearDatabase:GetGearData(GearName)
    if not GearData then
        return false;
    end

    local GearObject = self.__Gears[GearName];
    if not GearObject then
        GearObject = {
            Name = GearName,
            Amount = 0,
        }

        self.__Gears[GearName] = GearObject;
    end

    local ItemStackLimit = GearData.Stack_Limit or math.huge
    if GearObject.Amount + 1 > ItemStackLimit then
        return false;
    end

    GearObject.Amount += 1;

    return true;
end

function ClientGearStore.RemoveGear(self: AgentTypes.ClientGearManager, GearName: string)
    local GearObject = self.__Gears[GearName];

    if GearObject then
        GearObject.Amount -= 1;

        if GearObject.Amount < 1 then
            self.__Gears[GearName] = nil
        end

        return true
    end

    return false
end

function ClientGearStore.GetAddedGearStat(self: AgentTypes.ClientGearManager, Stat: AgentTypes.Stat)
    return 0
end

return ClientGearStore
