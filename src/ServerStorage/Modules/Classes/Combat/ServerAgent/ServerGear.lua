local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Database = Shared.Database
local Libraries = ServerStorage.Modules.Libraries

local GearTypes = require(Shared.Types.Gear)
local AgentTypes = require(Shared.Types.Agents)
local GearLibrary = require(Libraries.Gear)
local GearDatabase = require(Database.Gears)


--
local GearStore = {}
GearStore.__index = GearStore

function GearStore.new(ItemsClass: AgentTypes.AgentItemsClass): AgentTypes.ServerGearManager
    local self = setmetatable({}, GearStore)
    self.__Items = ItemsClass
    self.__Objects = {}
    self.__Gears = {}

    return self
end

function GearStore.AddGear(self: AgentTypes.ServerGearManager, GearName: string): boolean
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

function GearStore.RemoveGear(self: AgentTypes.ServerGearManager, GearName: string): boolean
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

function GearStore.AddObject(self: AgentTypes.ServerGearManager, Item: AgentTypes.AgentArtifactClass & AgentTypes.DriveObject)
    if self.__Objects[Item.Name] then
        return
    end

    self.__Objects[Item.Name] = Item
end

function GearStore.HasObject(self: AgentTypes.ServerGearManager, Name: string): boolean
    return self.__Objects[Name] ~= nil
end


function GearStore.RemoveObject(self: AgentTypes.ServerGearManager, Item: AgentTypes.AgentArtifactClass & AgentTypes.DriveObject)
    self.__Objects[Item.Name] = nil
end

function GearStore.RunHook(self: AgentTypes.ServerGearManager, HookId: GearTypes.HookId, Data: GearTypes.ProcessData)

    for _, Gear in self.__Gears do
        local GearClass = GearLibrary:Get(Gear.Name)

        if GearClass then
            GearClass:RunHook(HookId, Data)
        end
    end

end

function GearStore.RunEffectProcesses(self: AgentTypes.ServerGearManager, Event_Data: AgentTypes.ProcessEventData)
    local CountList = self.__Items:GetArtifactPieceEffects()

    for _, Item in self.__Objects do
        local ItemType = tostring(Item)

        if ItemType == 'ArtifactClass' then
            local ArtifactCount = CountList[Item.Name] or 0

            if ArtifactCount >= 2 then
                local Effect = Item:GetEventFor('Effect')
                if not Effect then
                    continue
                end

                task.spawn(Effect, Event_Data, ArtifactCount)
            end
        end
    end
end

function GearStore.RunHitProcesses(self: AgentTypes.ServerGearManager, State: AgentTypes.HitProcessState, Event_Data: AgentTypes.ProcessEventData)
    local CountList = self.__Items:GetArtifactPieceEffects()

    for _, Item in self.__Objects do
        local ItemType = tostring(Item)

        if ItemType == 'ArtifactClass' then
            local ArtifactCount = CountList[Item.Name] or 0
            if ArtifactCount >= 2 then
                local Effect = Item:GetEventFor(State .. "Hit")
                if not Effect then
                    continue
                end

                task.spawn(Effect, Event_Data, ArtifactCount)
            end
        end
    end
end

function GearStore.GetAddedGearStat(self: AgentTypes.ServerGearManager, Stat: AgentTypes.Stat)
    return 0
end

return GearStore