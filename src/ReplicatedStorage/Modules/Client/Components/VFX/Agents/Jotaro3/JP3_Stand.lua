--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local JotaroEffects = Assets.Effects.Agents.Jotaro3

local Agent = require(ReplicatedStorage.Modules.Client.Classes.Agent)
local Types = require(Shared.Types.Agents)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)

--- Need
local DEFAULT_ATTACHMENT_POSITION = Vector3.new(-2, 0.75, 1.75)
local Cache = {} :: {[Types.AgentClass]: AgentCache}

type AgentCache = {
    State: boolean,
    Thread: thread?,
    Model: Model?,
    Attachment: Attachment?,
    Visibility: boolean,
}
type EffectParams = {State: boolean?, Time: number?, At: Vector3?}

local function ToggleStandVisibility(Model: Instance, State: boolean, Animate: boolean?)
    local AgentCache: AgentCache = nil
    for Agent in Cache do
        local Obj = Cache[Agent]
        if Obj.Model == Model then
            AgentCache = Obj
        end
    end

    AgentCache.Visibility = State

    for _, BasePart: Instance in Model:GetDescendants() do
        if not BasePart:IsA("BasePart") or not BasePart:IsA("Texture") or not BasePart:IsA("Decal") then continue end
        local OriginalTransparency = BasePart:GetAttribute("OgTransparency")
        if not BasePart:GetAttribute("OgTransparency") then
            OriginalTransparency = BasePart.Transparency
            BasePart:SetAttribute("OgTransparency", OriginalTransparency)
        end

        local Goal = State and OriginalTransparency or 1
        if not Animate then
            BasePart.Transparency = Goal
        else
            Effects:Tween(BasePart, {.25, 'Cubic'}, {Transparency = Goal})
        end
    end

end

local function CreateModelFor(Agent: Types.AgentClass): ()
    local NewModel = JotaroEffects.StarPlatinum:Clone()
    NewModel:PivotTo(Agent:GetPivot())
    NewModel.Parent = workspace.World.Effects
    local ModelRoot = NewModel:FindFirstChild("HumanoidRootPart")

    local User = Instance.new('Attachment')
    User.Position = DEFAULT_ATTACHMENT_POSITION
    User.Parent = Agent:GetModel():FindFirstChild("HumanoidRootPart")

    local Stand = Instance.new('Attachment')
    Stand.Parent = ModelRoot

    local AlignPosition = Instance.new("AlignPosition")
    AlignPosition.Attachment0 = Stand
    AlignPosition.Attachment1 = User
    AlignPosition.Responsiveness = 35
    AlignPosition.MaxForce = math.huge
    AlignPosition.Parent = ModelRoot

    local AlignOrientation = Instance.new("AlignOrientation")
    AlignOrientation.Attachment0 = Stand
    AlignOrientation.Attachment1 = User
    AlignOrientation.Responsiveness = 45
    AlignOrientation.MaxTorque = math.huge
    AlignOrientation.Parent = ModelRoot

    ToggleStandVisibility(NewModel, false, false)

    Agent.__Character.__Appearance:BindObject(NewModel, ToggleStandVisibility)

    Cache[Agent].Model = NewModel
    Cache[Agent].Attachment = User
end

return function(Caster: Types.AgentClass, Data: EffectParams): ()
    local AgentCache = Cache[Caster] :: AgentCache
    if AgentCache == nil then
        AgentCache = {
            State = Data.State or false,
            Visibility = false,
        }
        Cache[Caster] = AgentCache
    end

    if AgentCache.Model == nil then
        CreateModelFor(Caster)
    end

    -- Logic
    local State = Data.State
    if State == nil and Data.At then
        local Attachment = AgentCache.Attachment :: Attachment
        Attachment.Position = Data.At

        if not AgentCache.Visibility then
            ToggleStandVisibility(AgentCache.Model :: Model, true)
        end

        AgentCache.Thread = task.delay(Data.Time, function()
            if not AgentCache.State then
                ToggleStandVisibility(AgentCache.Model :: Model, false)
            end

            Attachment.Position = DEFAULT_ATTACHMENT_POSITION
        end)
    elseif State ~= nil then
        local Attachment = AgentCache.Attachment :: Attachment
        Attachment.Position = if State == true then DEFAULT_ATTACHMENT_POSITION else Vector3.zero

        AgentCache.State = State
        ToggleStandVisibility(AgentCache.Model :: Model, State)
    end
end