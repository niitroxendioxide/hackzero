local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Modules = ServerStorage.Modules
local Shared = ReplicatedStorage.Modules.Shared


local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)
local Products = require(Shared.Database.Products)
local DataService = require(Modules.Services.Data.DataService)

--
local Service = {
    __Queue = {},
}

type BoughtHandler = () -> ()

--
local function HandleCancelledPurchase(PlayerId, Id: number, Bought: number)
    local Player = typeof(PlayerId) == 'number' and Players:GetPlayerByUserId(PlayerId) or PlayerId

    if Bought or not Service.__Queue[Player] then
        return
    end

    if not Service.__Queue[Player] then
        return
    end

    Service.__Queue[Player] = nil
end

local function ProductProcessed(ReceiptInfo)
    local Player = Players:GetPlayerByUserId(ReceiptInfo.PlayerId)
    local ProductId = ReceiptInfo.ProductId

    local PlayerObjectQueue = Service.__Queue[Player]
    if not PlayerObjectQueue then
        return
    end

    local CurrentProductQueue = Service.__Queue[Player].ProductId == ProductId
    if not CurrentProductQueue then return end

    PlayerObjectQueue.Handler()

    Service.__Queue[Player] = nil

    return Enum.ProductPurchaseDecision.PurchaseGranted
end

--
function Service:Init()
    Network.new("Shop", 'Event')

    --
    MarketplaceService.ProcessReceipt = ProductProcessed
    MarketplaceService.PromptProductPurchaseFinished:Connect(HandleCancelledPurchase)

    Network:On("Shop", Service.__On_Event)
end

--
function Service:IsInQueue(Player: Player, Id: number)
    return (Service.__Queue[Player] ~= nil)
end

function Service:WaitForPurchaseComplete(Player: Player, Id: number, Handler: BoughtHandler)
    if Service:IsInQueue(Player, Id) then
        return
    end

    Service.__Queue[Player] = {
        ProductId = Id,
        Handler = Handler,
    }
end

function Service:PromptGemProduct(Player: Player, Size: string)
    local ProductData = Products.Dev_Products.Gems[Size]
    local ProductId = ProductData and ProductData.Product_Id

    if not ProductData or Service:IsInQueue(Player, ProductId) then
        return
    end

    Service:WaitForPurchaseComplete(Player, ProductId, function(b)
        DataService:Increase(Player, 'Gems', ProductData.Amount)
    end)

    MarketplaceService:PromptProductPurchase(Player, ProductId)
end

--
function Service.__On_Event(Player: Player, Type: number, Request: {})
    if Type == GameEnum.MarketplaceRequestTypes.BuyProduct then
        local ProductType = Request[1]
        local Size = Request[2]

        if ProductType == 'Gem' then
            Service:PromptGemProduct(Player, Size)
        end
    end
end


return Service