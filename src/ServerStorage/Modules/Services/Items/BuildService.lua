--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Services = Modules.Services
local Shared = ReplicatedStorage.Modules.Shared


local Companions = require(ReplicatedStorage.Modules.Shared.Types.Companions)
local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local Statics = require(Shared.Database.Statics)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Types = require(Shared.Types)

local DataService = require(Services.Data.DataService)
local AgentDatabase = require(Shared.Database.Characters)
local ItemDatabase = require(Shared.Database.Items)

---
local CHIPS_PREFIX = {
    [1] = '',
    [2] = 'Upgraded',
    [3] = 'Tier3',
}

-- Artifacts
local function AddArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Add, Artifact:Compress(), Agent.Name, Agent.Artifacts
    })
end

local function RemoveArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Remove, Artifact:Compress(), Agent.Name, Agent.Artifacts
    })
end

local function UpdateArtifact(Player: Player, Artifact: Types.PlayerArtifactDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateArtifactSlot, {
        GameEnum.ChangeEvents.Update, Artifact:Compress(),
    })
end

--
local function AddDrive(Player: Player, Drive: Types.PlayerDriveDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Add, Drive:Compress(), Agent.Name,
    })
end

local function RemoveDrive(Player: Player, Drive: Types.PlayerDriveDataClass, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Remove, Drive:Compress(), Agent.Name
    })
end

local function UpdateDrive(Player: Player, Drive: Types.PlayerDriveDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpdateDrive, {
        GameEnum.ChangeEvents.Update, Drive:Compress(),
    })
end

local function UpdateSkills(Player: Player, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.UpgradeAgentSkill, {Agent.Name, Agent.Skills})
end

local function UpdateCompanionLevel(Player: Player, Companion: Companions.PlayerCompanionDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.LevelCompanion, Companion:Compress())
end

local function AscendAgent(Player: Player, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.AscendAgent, {Agent.Name, Agent.Ascensions})
end

local function UpdateAgentLevel(Player: Player, Agent: Types.PlayerAgentDataClass): ()
    Network:Fire('UpdateAgent', Player, GameEnum.BuildEvent.LevelAgent, {Agent.Name, Agent.Level, Agent.Experience})
end


--[[
    Handles setting up the builds & using the data from the player artifacts & more
]]
local Service = {}

function Service:Init()
    Network.new("UpdateAgent", 'Event')
    Network:On("UpdateAgent", Service.__HandleEvent)
end

function Service.__HandleEvent(Player: Player, Type: number, Request: {})
    if Type == GameEnum.BuildEvent.UpdateArtifactSlot then
        Service:SetAgentArtifactSlot(Player, Request[1], Request[2])
    elseif Type == GameEnum.BuildEvent.UpdateDrive then
        Service:SetAgentDrive(Player, Request[1], Request[2])
    elseif Type == GameEnum.BuildEvent.UpgradeAgentSkill then
        Service:UpgradeAgentSkill(Player, Request[1], Request[2], Request[3])
    elseif Type == GameEnum.BuildEvent.AscendAgent then
        Service:AscendAgent(Player, Request[1], Request[2])
    elseif Type == GameEnum.BuildEvent.LevelAgent then
        Service:LevelAgent(Player, Request[1], Request[2])
    elseif Type == GameEnum.BuildEvent.LevelCompanion then
        Service:UpgradeCompanion(Player, Request[1], Request[2])
    end
end

function Service:LevelAgent(Player: Player, AgentName: string, Items: {})
    local Agent = DataService:GetAgent(Player, AgentName)

    if Agent.Level >= Statics.Max_Character_Level then
        Debugger:DebugLine("Agent Level", `Character maxxed out: {AgentName}`, 1)

        return
    end

    --
    local TotalExperience = 0
    local MaxExperience = Statics.GetExperienceForMax(Agent.Level, Agent.Experience)

    local Keys = {}
    for Item in Items do
        table.insert(Keys, Item)
    end

    table.sort(Keys, function(a0, a1): boolean
        local AItem = ItemDatabase:GetItemData(a0)
        local BItem = ItemDatabase:GetItemData(a1)

        return (BItem.Other.FeedExp < AItem.Other.FeedExp) 
    end)


    for _, Item in Keys do
        local Count = Items[Item]
        local ItemInfo = ItemDatabase:GetItemData(Item)
        if not ItemInfo or not ItemInfo.Other.FeedExp then continue end

        local HasAmount = DataService:HasItem(Player, Item, Count)
        if not HasAmount then
            continue
        end

        local UsedCount = 1
        for CurCount = Count, 1, -1 do
            if (TotalExperience + ItemInfo.Other.FeedExp * CurCount) <= MaxExperience then
                if (Count >= CurCount + 1) and (TotalExperience + ItemInfo.Other.FeedExp * (CurCount + 1) >= MaxExperience) then
                    UsedCount = CurCount + 1
                    break
                end

                UsedCount = CurCount
                break
            end
        end

        local Amount = UsedCount * ItemInfo.Other.FeedExp

        DataService:TakeItem(Player, Item, UsedCount)
        TotalExperience += Amount
    end

    local Next = Statics.Experience_For_Level(Agent.Level + 1)
    Agent.Experience += TotalExperience

    while Agent.Experience >= Next do
        Agent.Experience -= Next
        Agent.Level += 1
        Next = Statics.Experience_For_Level(Agent.Level + 1)

        if Next == nil then
            break;
        end
    end

    DataService:SyncPlayerItems(Player)
    UpdateAgentLevel(Player, Agent)
end

function Service:UpgradeDrives()
    print('TODO Later')
end

function Service:AscendAgent(Player: Player, AgentName: string, Times: number)
    local Agent = DataService:GetAgent(Player, AgentName)

    Times = Times or 1

    if Agent.Ascensions + Times > 6 then
        return
    end

    local ItemName = 'AgentToken:'..AgentName
    local HasOfItem = DataService:HasItem(Player, ItemName, Times)
    if not HasOfItem then
        return
    end
    
    Agent:SetAscensions(Agent.Ascensions + Times)
    DataService:TakeItem(Player, ItemName, Times)

    --

    DataService:SyncPlayerItems(Player)
    AscendAgent(Player, Agent)
end

function Service:UpgradeAgentSkill(Player: Player, AgentName: string, SkillName: number, ItemsUsed: { [number]: number })
    local Agent = DataService:GetAgent(Player, AgentName)

    if not Agent.Skills[SkillName] or (Agent.Skills[SkillName] + 1 > 20) then
        return
    end

    local AgentData = AgentDatabase:GetCharacterData(AgentName)
    local Element = AgentData.Element
    local Cost = Statics.Skill_Upgrade_Cost(Agent.Skills[SkillName] + 1)
    local ItemName = Element..'Chip'

    local TotalUsedAmount = 0;
    for Tier, Amount in ItemsUsed do
        if Amount <= 0 then
            continue
        end

        TotalUsedAmount += math.max((Tier-1) * 3, 1) * Amount

        local HasOfItem = DataService:HasItem(Player, CHIPS_PREFIX[Tier] .. ItemName, Amount)
        if not HasOfItem then
            print('User doesnt have enough of: ', CHIPS_PREFIX[Tier] .. ItemName)

            return false
        end
    end

    if TotalUsedAmount < Cost then
        return
    end

    local Refund = {}
    while (TotalUsedAmount > Cost) do
        local Difference = TotalUsedAmount - Cost
        for Tier = 3, 1, -1 do
            local TierUpgradeAmount = math.max((Tier-1) * 3, 1)

            while Difference % TierUpgradeAmount == 0 and Difference > 0 do
                Refund[Tier] = (Refund[Tier] or 0) + 1;
                TotalUsedAmount -= TierUpgradeAmount
                Difference = math.max(TotalUsedAmount - Cost, 0)
            end
        end
    end

    for Tier, Amount in ItemsUsed do
        local Refunded = Refund[Tier] or 0
        local ActualTaken = Amount - Refunded

        if ActualTaken > 0 then
            DataService:TakeItem(Player, CHIPS_PREFIX[Tier] .. ItemName, ActualTaken)
        elseif ActualTaken < 0 then
            DataService:AddItem(Player, CHIPS_PREFIX[Tier] .. ItemName, Refunded)
        end
    end

    Agent:SetSkill(SkillName, Agent.Skills[SkillName] + 1)

    DataService:UpdatePlayerItems(Player)
    UpdateSkills(Player, Agent)

    return true
end

function Service:SetAgentArtifactSlot(Player: Player, AgentName: string, ArtifactId: string)
    local Artifact = DataService:GetArtifacts(Player, function(Artifact)
        return Artifact.__Id == ArtifactId
    end, true) :: Types.PlayerArtifactDataClass

    local Agent = DataService:GetAgent(Player, AgentName)
    local UnequippedAgent, ReplacedSlotId = Artifact:EquipTo(Agent)

    if UnequippedAgent == Agent then
        RemoveArtifact(Player, Artifact, Agent)
    else
        AddArtifact(Player, Artifact, Agent)

        if UnequippedAgent then
            RemoveArtifact(Player, Artifact, UnequippedAgent)
        end
    end

    if ReplacedSlotId then
        local OldArtifact = DataService:GetArtifacts(Player, function(QueryArtifact)
            return QueryArtifact.__Id == ReplacedSlotId
        end, true) :: Types.PlayerArtifactDataClass

        OldArtifact:EquipTo(nil)

        UpdateArtifact(Player, OldArtifact)
    end
end

function Service:SetAgentDrive(Player: Player, AgentName: string, DriveId: string)
    local Drive = DataService:GetDrives(Player, function(QueryDrive)
        return QueryDrive.__Id == DriveId
    end, true) :: Types.PlayerDriveDataClass

    local Agent = DataService:GetAgent(Player, AgentName)

    local UnequippedAgent, ReplacedDriveId = Drive:EquipTo(Agent)

    if UnequippedAgent == Agent then
        RemoveDrive(Player, Drive, Agent)
    else
        AddDrive(Player, Drive, Agent)

        if UnequippedAgent then
            RemoveDrive(Player, Drive, UnequippedAgent)
        end
    end

    if ReplacedDriveId then
        local OldDrive = DataService:GetDrives(Player, function(QueryDrive)
            return QueryDrive.__Id == ReplacedDriveId
        end, true) :: Types.PlayerDriveDataClass

        OldDrive:EquipTo(nil)

        UpdateDrive(Player, OldDrive)
    end
end


function Service:UpgradeCompanion(Player: Player, CompanionId: string, Items: {[string]: number})
    local Companion = DataService:GetOrCreateCompanion(Player, CompanionId)

    if Companion.__Level >= Statics.Max_Companion_Level then
        return
    end

    --
    local TotalExperience = 0
    local NextLevelExperience = Statics.Companion_Experience_For_Level(Companion.__Level + 1)

    for Item, Count in Items do
        local ItemInfo = ItemDatabase:GetItemData(Item)
        if not ItemInfo or not ItemInfo.Other.FeedExp then continue end

        local HasAmount = DataService:HasItem(Player, Item, Count)
        if not HasAmount then
            continue
        end

        if (TotalExperience + ItemInfo.Other.FeedExp > NextLevelExperience) and (Companion.__Level + 1) > Statics.Max_Companion_Level then
            continue
        end

        local Amount = Count * ItemInfo.Other.FeedExp

        DataService:TakeItem(Player, Item, Count)
        TotalExperience += Amount
    end

    local Next = Statics.Companion_Experience_For_Level(Companion.__Level + 1)
    Companion.__Experience += TotalExperience

    while Companion.__Experience >= Next do
        Companion.__Experience -= Next
        Companion.__Level += 1
        Next = Statics.Companion_Experience_For_Level(Companion.__Level + 1)
    end

    DataService:SaveCompanion(Player, Companion)
    UpdateCompanionLevel(Player, Companion)
end

return Service
