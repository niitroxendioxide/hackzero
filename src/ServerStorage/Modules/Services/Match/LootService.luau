local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Libraries = ServerStorage.Modules.Libraries

local Types = require(Shared.Types.Stages)
local Signal = require(Shared.Utility.Signal)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local PlayersLibrary = require(Libraries.Players)


--
type ChestObject = {
    Opened: boolean,
    Items: {Types.LootItem},
    Base: BasePart,
    Id: number,
}

local Service = {
    OnLootboxOpened = nil :: Signal.ScriptSignal<Player, {Items: {[string]: {}}}>?;
}

local Chests = {} :: {ChestObject}

--
local function Replicate(...)
    Network:FireForAll("Replicate", ...)
end

local function ChestInteractionEvent(Player: Player, Type: number, ChestId: number)
    if not Chests[ChestId] then
        return
    end

    local StagePlayer = PlayersLibrary:Get(Player)
    local ChestObject = Chests[ChestId]

    if GameEnum.ChestInteractions.Open == Type then
        if ChestObject.Opened then return end

        local ItemList = {}
        for _, ItemObject in ChestObject.Items do
            table.insert(ItemList, {ItemObject.Type, ItemObject.Amount, ItemObject.Extra and ItemObject.Extra.Name or ""})
            
            StagePlayer:AddLoot(ItemObject.Type, {Amount = ItemObject.Amount, Extra = ItemObject.Extra or {}})
        end

        Network:FireForAll("ChestInteraction", Player, ChestId, ItemList)
    end

end

--
function Service:Init()
    Service.OnLootboxOpened = Signal.new()

    Network.new("ChestInteraction", "Event")
    Network:On("ChestInteraction", ChestInteractionEvent)
end

function Service:SetupChests(Chest_Data: {{ItemList: {}, Parts: {BasePart}}})
    for _, ChestObject in Chest_Data do
        if not ChestObject.ItemList or not ChestObject.Parts then
            continue
        end

        for _, Part in ChestObject.Parts do
            local Id = #Chests + 1
            local Buf = buffer.create(3)
            buffer.writeu8(Buf, 0, GameEnum.Replication.CreateChest)
            buffer.writeu16(Buf, 1, Id)

            local ChestDataObject = {
                Items = ChestObject.ItemList,
                Base = Part,
                Opened = false,
                Id = Id,
            }

            table.insert(Chests, ChestDataObject)

            Replicate(Buf, Part)
        end
    end

end

return Service