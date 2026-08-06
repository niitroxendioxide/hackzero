---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local _RunService = game:GetService("RunService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Animation = require(Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

local EffectsLibrary = require(Client.Libraries.Effects)

--- Saved stuff
local Cache = {}
local Anim = nil;

---
return function(
    Caster: Types.Caster,
    Id: number,
    State: string,
    ...
): ()
    if Anim == nil then
        Animation:GetAnim("Characters.Chihiro.Abilities.Special.Fish.Smallidle")
    end

    local KuroAssets = Assets.Chihiro.Kuro
    local CasterLook = Caster:GetPivot().LookVector
    local Args = {...}

    if Cache[Caster] == nil then
        Cache[Caster] = {}
    end

    local FishIdData = Cache[Caster][Id]

    ---
    if State == 'Cleanup' then
        if not FishIdData then return end

        FishIdData.Cleanup()
        Cache[Caster][Id] = nil 
    elseif State == 'Create' then
        local Position = Args[1] :: vector
        local NewFishy = Effects:Create(Assets.Chihiro.SmallKoi, 45)
        NewFishy:PivotTo(CFrame.lookAlong(Position, CasterLook) * CFrame.Angles(math.pi/2, 0, 0) * CFrame.Angles(0, 0, Effects:Random(-math.pi, math.pi)))
        NewFishy:ScaleTo(0.001)

        Animation:Play(NewFishy, Anim, 0, 1, Effects:Random(0.09, 0.2))

        Effects:TweenModel(NewFishy, 0.25, 0.45, 'Quad')

        local SpawnEffect = Effects:Create(KuroAssets.SpawnFishy, 2)
        SpawnEffect:PivotTo(NewFishy:GetPivot())
        Effects:Emit(SpawnEffect, true)

        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.new()
        Highlight.FillTransparency = 0
        Highlight.OutlineTransparency = 1
        Highlight.Parent = NewFishy
        
        Effects:CleanUp(Highlight, 0.75)
        Effects:Tween(Highlight, {.75, 'Sine'}, {FillTransparency = 1})

        Cache[Caster][Id] = {
            Model = NewFishy,
            Position = Position,
            Cleanup = function()
                Effects:Tween(NewFishy.PrimaryPart, { 0.15 }, {Transparency = 1})

                Effects:CleanUp(NewFishy, 0.25)
            end
        }
    elseif State == 'Shoot' then
        local Direction = Args[1] :: vector
        local Position = FishIdData.Position;

        local ProjectileCFrame = CFrame.lookAlong(Position, Direction);
        local KuroEffect = Effects:Create(KuroAssets.SlashModel, 4.5)
        KuroEffect:PivotTo(ProjectileCFrame)
        KuroEffect:ScaleTo(0.25)
        KuroEffect.Ground:Destroy()

        FishIdData.Cleanup()
        Cache[Caster][Id] = nil

        local Cleaned = false
        local function CleanupProjectile()
            if Cleaned then return end

            Cleaned = true

            Effects:Toggle(KuroEffect, false)
            Effects:Tween(KuroEffect:FindFirstChild('Highlight'), { 0.15 }, {FillTransparency = 1, OutlineTransparency = 1})

            for _, BasePart in KuroEffect:GetChildren() do
                if BasePart:IsA('MeshPart') then
                    Effects:Tween(BasePart, { 0.25 }, {Transparency = 1})
                end
            end
        end
        Effects:CleanUp(CleanupProjectile, 1)

        Effects:MoveProjectile(KuroEffect, vector.create(5.5, 3.7), 75, 2, function(Target): boolean
            CleanupProjectile()
            EffectsLibrary:Play("Hit", Target, {
                HighlightColor = Color3.new(),
                Emitter = 'KuroHit',
                Highlight = true,
                Audio = {
                    Id = { 785201669 },
                    Volume = 0.35,
                }
            })

            ---
            return true
        end)
    end
end