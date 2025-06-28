--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local JotaroEffects = Assets.Effects.Agents.Jotaro3

local AnimLib = require(Client.Libraries.Animation)
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
    RemoveParticles: (() -> ())?,
}
type EffectParams = {State: boolean?, Time: number?, At: Vector3?}

local function ToggleStandVisibility(Model: Instance, State: boolean, ExtraState: number?)
    local AgentCache: AgentCache = nil
    for _, Obj in Cache do
        if Obj.Model == Model then
            AgentCache = Obj
        end
    end

    if AgentCache == nil then
        return
    end

    if ExtraState == 1 and AgentCache.State ~= true then
        State = false
    end

    AgentCache.Visibility = State

    for _, BasePart: Instance in Model:GetDescendants() do
        if not BasePart:IsA("BasePart") and not BasePart:IsA("Texture") and not BasePart:IsA("Decal") then 
            continue
        end

        local OriginalTransparency = BasePart:GetAttribute("OgTransparency") :: number
        if not BasePart:GetAttribute("OgTransparency") then
            OriginalTransparency = BasePart.Transparency
            BasePart:SetAttribute("OgTransparency", OriginalTransparency)
        end

        local Goal: number = (State == true) and OriginalTransparency or 1
        if ExtraState == 2 then
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
    NewModel.Name = Agent.PlayerId..'SPstandmodel'

    for _, BasePart: BasePart in NewModel:GetDescendants() do
        if BasePart:IsA('BasePart') then
            BasePart.Massless = true
            BasePart.CollisionGroup = 'Effects'
        end
    end

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

    ToggleStandVisibility(NewModel, false, 2)

    local Idle = AnimLib:GetAnim('Characters.Jotaro3.Abilities.SP_Idle')
    local Moving = AnimLib:GetAnim('Characters.Jotaro3.Abilities.SP_Movement')
    AnimLib:Play(NewModel, Idle)

    local MovingTrack = AnimLib:Play(NewModel, Moving)

    Agent.__Character.__Appearance:BindObject(NewModel, ToggleStandVisibility)
    Agent.__Character.__Animator:AddModelMovingAnimation(MovingTrack, 1)

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
        local Model = AgentCache.Model :: Model
        local Attachment = AgentCache.Attachment :: Attachment
        Attachment.Position = Data.At

        if AgentCache.Thread then
            task.cancel(AgentCache.Thread)
        end

        if not AgentCache.Visibility then
            ToggleStandVisibility(Model, true)
        end

        AgentCache.Thread = task.delay(Data.Time, function()
            if AgentCache.State == false then
                ToggleStandVisibility(Model, false)
                Attachment.Position = Vector3.zero
            else
                Attachment.Position = DEFAULT_ATTACHMENT_POSITION
            end
        end)
    elseif State ~= nil then
        local CasterModel = Caster:GetModel()
        local Attachment = AgentCache.Attachment :: Attachment
        Attachment.Position = if State == true then DEFAULT_ATTACHMENT_POSITION else Vector3.zero
        if State == true then
            local Light = Instance.new('PointLight')
            Light.Color = Color3.fromRGB(144, 88, 255)
            Light.Parent = CasterModel.PrimaryPart
            Light.Name = 'StandLight'
            Light.Brightness = 0
            Light.Range = 8

            Effects:Tween(Light, {.25}, {Brightness = 3})
            Caster.__Character.__Appearance:BindParticles(CasterModel.PrimaryPart :: BasePart)

            for _, BodyPart in Caster:GetModel():GetChildren() do
                if BodyPart:IsA("BasePart") and BodyPart.Name ~= 'HumanoidRootPart' then
                    if BodyPart:FindFirstChild('JOTAROPARTICLEAURA') then
                        continue
                    end

                    for _, Particle in Assets.Effects.Agents.Jotaro3.Aura:GetChildren() do
                        local Clone = Particle:Clone()
                        Clone.Name = 'JOTAROPARTICLEAURA'
                        Clone.Parent = BodyPart
                    end

                    Caster.__Character.__Appearance:BindParticles(BodyPart)
                end
            end

            AgentCache.RemoveParticles = function()
                local Light = (CasterModel:FindFirstChild('HumanoidRootPart') :: BasePart):FindFirstChild('StandLight')
                if Light then
                    Light.Name = '__Dl'
                    Effects:Tween(Light, {.25}, {Brightness = 0})
                    Effects:CleanUp(Light, 1)
                end

                for _, BodyPart in Caster:GetModel():GetChildren() do
                    if BodyPart:IsA("BasePart") then
                        local Object = BodyPart:FindFirstChild("JOTAROPARTICLEAURA") ::ParticleEmitter?
                        while Object ~= nil do
                            Object.Name = 'destroying_particle'
                            Object.Enabled = false
                            Effects:CleanUp(Object, 1)

                            Object = BodyPart:FindFirstChild("JOTAROPARTICLEAURA") :: ParticleEmitter?
                        end

                        Caster.__Character.__Appearance:UnbindParticles(BodyPart)
                    end
                end
            end

        else
            if AgentCache.RemoveParticles then
                AgentCache.RemoveParticles()
            end
        end

        AgentCache.State = State
        ToggleStandVisibility(AgentCache.Model :: Model, State)
    end
end