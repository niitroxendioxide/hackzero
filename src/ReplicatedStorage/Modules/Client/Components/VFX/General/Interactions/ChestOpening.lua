local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

---
type FloatingItem = {
    Model: Model,
    Target: Model,
    Dir: CFrame,
    Origin: vector,
    Goal: vector,
    Mid: vector,
    Created: number,
    PickupTime: number,
    Offset: vector,
    Tweening: boolean,
}

---
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Assets = ReplicatedStorage.Assets.Effects
local Models = ReplicatedStorage.Assets.Items
local Effects = require(Shared.Utility.Effects)

local AgentsLib = require(Client.Libraries.Characters)

local FloatingItemsActive = false
local FloatingItems = {} :: { FloatingItem }

function SetupFloatingItems()
    if FloatingItemsActive then
        return;
    end

    FloatingItemsActive = true

    RunService.Heartbeat:Connect(function(_: number)
        for Idx = #FloatingItems, 1, -1 do
            local Item = FloatingItems[Idx]
            local Elapsed = (os.clock() - Item.Created)
            if (Elapsed > (Item.PickupTime + 0.3)) and not Item.Tweening then
                Item.Tweening = true
                Effects:TweenModel(Item.Model, 0, 0.2, 'Quad')
                Effects:CleanUp(Item.Model, 0.2)
                continue
            elseif (Elapsed > Item.PickupTime + 0.45) then
                local PickupVFX = Effects:Create(Assets.General.Interactions.PickupItemVFX, 1)
                PickupVFX.Anchored = false
                PickupVFX:PivotTo(Item.Target:GetPivot())
                Effects:Emit(PickupVFX)
                Effects:Weld(PickupVFX, Item.Target.PrimaryPart)

                table.remove(FloatingItems, Idx)
                continue
            end

            local Alpha = math.min(Elapsed / 0.6, 1)
            local Position;

            if Elapsed > Item.PickupTime then
                if not Item.Tracking then
                    for _, Particle in Item.Model.ItemVFX:GetDescendants() do
                        if Particle.Name == 'Tall' then
                            Particle:Destroy()
                        end
                    end

                    Item.Tracking = true
                end

                local Delta = math.min((Elapsed - Item.PickupTime) / 0.45, 1)
                local TargetPoint = Item.Target:GetPivot().Position
                local MidPoint = CFrame.lookAt(Item.Origin, TargetPoint) * CFrame.new(Item.Offset.x, Item.Offset.y, -(Item.Origin - TargetPoint).Magnitude/2)
                local Value = TweenService:GetValue(Delta, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                Position = Effects:Quad(Item.Goal, MidPoint.Position, TargetPoint, Value)
                
            elseif Alpha >= 1 then
                local Angle = ((Elapsed - 0.6) / 0.5) * math.pi

                Position = vector.create(Item.Goal.X, Item.Goal.Y + math.sin(Angle) * 0.5, Item.Goal.Z)
            else
                Position = Effects:Quad(Item.Origin, Item.Mid, Item.Goal, Alpha)
            end

            local Rotation = math.pi * 0.25 * Elapsed
            Item.Model:PivotTo(CFrame.new(Position) * Item.Dir * CFrame.Angles(0, Rotation, 0))
        end
    end)
end

function AddItem(Model: Model, Origin: vector, Goal: vector, Target: Model, PickupTime: number?)
    local Seed = Random.new(math.random(10000))
    AddEffectToModel(Model)

    table.insert(FloatingItems, {
        Model = Model,
        Origin = Origin,
        Dir = CFrame.Angles(0, Effects:Random(-math.pi, math.pi), 0),
        Goal = Goal,
        Mid = (CFrame.lookAt(Origin, Goal) * CFrame.new(0, (Goal - Origin).Magnitude, (Goal - Origin).Magnitude / -2)).Position,
        Target = Target,
        Created = os.clock(),
        Offset = vector.create(Seed:NextNumber(-3, 3), Seed:NextNumber(-3, 3)),
        PickupTime = PickupTime or 2,
        Tracking = false
    })
end

function AddEffectToModel(Model: Model)
    local Particles = Effects:Create(Assets.General.Interactions.ItemVFX, nil, Model)
    Particles:PivotTo(Model:GetPivot())
    Effects:Weld(Particles, Model.PrimaryPart)
end

return function(
    At: CFrame,
    Items: {},
    Player: Player
)
    if not FloatingItemsActive then
        SetupFloatingItems()
    end

    local PlrId = Player:GetAttribute("ReplicationId") :: number
    local Agent = AgentsLib:GetCurrent(PlrId)

    local Vfx = Effects:Create(Assets.General.Interactions.OpenChest, 2)
    Vfx:PivotTo(At * CFrame.new(0, 1, 0))

    local FoundGold = false
    local FoundGems = false
    for _, Item in Items do
        local Xs, Zs = if Effects:RandomInt(0, 1) == 1 then -1 else 1, if Effects:RandomInt(0, 1) == 1 then -1 else 1
        local RandomAround = At * CFrame.new(Effects:Random(2, 6) * Xs, 0, Effects:Random(2, 6) * Zs)
        local CastGround = Effects:CastMapRaycast(RandomAround.Position, vector.create(0, -15))
        local Pos = (CastGround and CastGround.Position or RandomAround.Position) + vector.create(0, 1.5, 0)

        if Item[1] == 'Gold' then
            FoundGold = true
        elseif Item[1] == 'Gems' then
            FoundGems = true
        elseif Item[1] == 'Artifact' then
            local Model = Models.Artifacts:FindFirstChild(Item[3])
            if (Model == nil) then
                Model = Models.Artifacts.Default:Clone()
            elseif Model:IsA('Folder') then
                Model = Model:GetChildren()[math.random(1, #Model:GetChildren())]:Clone()
            elseif Model:IsA('Model') then
                local Cloned = Model:Clone()

                if Cloned:HasTag('RandomColor') then
                    for _, Descendant in Cloned:GetDescendants() do
                        if Descendant:HasTag('Recolorable') then
                            Descendant.Color = Color3.fromHSV(Effects:RandomInt(0, 360) / 360, 170/255, 1)
                        end
                    end
                end

                Model = Cloned
            end

            Model.Parent = workspace.World.Effects
            Effects:CleanUp(Model, 5)

            AddItem(Model, At.Position, Pos, Agent:GetModel())
        end
    end

    if not FoundGold then
        Vfx.Attachment.Coins:Destroy()
    end

    if not FoundGems then
        Vfx.Attachment.Gems:Destroy()
    end

    Vfx.Parent = workspace.World.Effects
    Effects:Emit(Vfx, true)
end
