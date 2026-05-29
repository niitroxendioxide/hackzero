local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Assets = ReplicatedStorage.Assets.Interface

local Icons = require(ReplicatedStorage.Modules.Shared.Database.Icons)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local Types = require(Shared.Types)
local ItemsDB = require(Shared.Database.Items)
local ArtifactsDB = require(Shared.Database.Artifacts)
local ComponentClass = require(Client.Classes.Interface)

--
local function FadeItem(ItemFrame)
    for _, Item in ItemFrame.Design:GetChildren() do
        if Item:IsA('UIStroke') then
            Effects:Tween(Item, { .3, 'Quad' }, {Transparency = 1})
        elseif Item:IsA('ImageLabel') then
            Effects:Tween(Item, { .3, 'Quad' }, {ImageTransparency = 1})
        end
    end

    Effects:Tween(ItemFrame.Design.Label, { .3, 'Quad' }, {TextTransparency = 1})
    Effects:Tween(ItemFrame.Design.Label.UIStroke, { .3, 'Quad' }, {Transparency = 1})
    Effects:Tween(ItemFrame.Design, { 0.275, 'Quad' }, { BackgroundTransparency = 1 })
    Effects:Tween(ItemFrame, { 0.45, 'Sine' }, {Size = UDim2.fromScale(0.85, 0)})
    Effects:CleanUp(ItemFrame, 0.45)
end

local Threads = {}
local Component = ComponentClass.new(script.Name, 'HUD', {})

function Component:Link(): Instance?
	local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("PlayerHUD", 10) :: ScreenGui
	if not HUD then return end
	local Main = HUD:FindFirstChild("ItemNotifications", true)

	return Main;
end

function Component:Init()
    local MainFrame = Component:GetFrame()
    MainFrame.Visible = true
end

local Priorities = {Gold = 0, Gems = 1, Item = 23, Artifact = 25, Drive = 26}
function Component:AddItem(Type: string, Amount: number, Name: string?)
    local MainFrame = Component:GetFrame()
    local Stackable = Type == 'Gold' or Type == 'Gems' 

    if Stackable and MainFrame.List:FindFirstChild(Type) and Threads[Type] then
        local Item = MainFrame.List:FindFirstChild(Type)
        local NewAmt = Item:GetAttribute('Amount') + Amount
        Item:SetAttribute('Amount', NewAmt)

        Item.Design.Label.Text = 'x'..NewAmt.." "..(Type)
        task.cancel(Threads[Type])
        Threads[Type] = task.delay(2.5, FadeItem, Item)

        return
    end

    local ItemName = if (Name ~= nil and #Name > 0) then Name else Type
    local ItemFrame = Assets.Items.Notification:Clone()
    ItemFrame.Parent = MainFrame.List
    ItemFrame.Name = Type
    ItemFrame.LayoutOrder = Priorities[Type] or 27
    ItemFrame:SetAttribute('Amount', Amount)
    if Type == 'Artifact' or Type == 'Drive' then
        ItemFrame.Design.Label.Text = `{Type}: "{ItemName}"`
    else
        ItemFrame.Design.Label.Text = 'x'..Amount.." "..(ItemName)
    end

    local GotIcon = Icons.Currency[Type]
    if not GotIcon then
        ItemFrame.Design.Icon.Visible = false
        ItemFrame.Design.Label.Position = UDim2.fromScale(0.024, 0.109)
    else
        ItemFrame.Design.Icon.Image = "rbxassetid://" .. GotIcon
    end

    --- Animate Fade In
    ItemFrame.Design.Position = UDim2.fromScale(0.3, 0.5)
    for _, Item in ItemFrame.Design:GetChildren() do
        if Item:IsA('UIStroke') then
            local Transparency = Item.Transparency
            Item.Transparency = 1
            Effects:Tween(Item, { .4, 'Quad' }, {Transparency = Transparency})
        elseif Item:IsA('ImageLabel') then
            local ImgTrans = Item.ImageTransparency
            Item.ImageTransparency = 1
            Effects:Tween(Item, { .35, 'Quad' }, {ImageTransparency = ImgTrans})
        end
    end

    ItemFrame.Design.Label.TextTransparency = 1
    ItemFrame.Design.Label.UIStroke.Transparency = 1
    Effects:Tween(ItemFrame.Design.Label, { .35, 'Quad' }, {TextTransparency = 0})
    Effects:Tween(ItemFrame.Design.Label.UIStroke, { .35, 'Quad' }, {Transparency = 0})

    Effects:Tween(ItemFrame.Design, { 0.35, 'Quad' }, { BackgroundTransparency = 0.5 })
    Effects:Tween(ItemFrame.Design, { 0.25, 'Quart' }, { Position = UDim2.fromScale(0, 0.5) })

    if Stackable then
        Threads[Type] = task.delay(2.5, FadeItem, ItemFrame)
    else
        task.delay(2.5, FadeItem, ItemFrame)
    end
end

return Component :: Types.UIComponent
