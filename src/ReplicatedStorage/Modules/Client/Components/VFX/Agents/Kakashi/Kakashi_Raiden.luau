---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)
local ForgeVFX = require(ReplicatedStorage.Packages.ForgeVFX)

local AnimationLibrary = require(Client.Libraries.Animation) 
local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    const Args = {...}

    const NarutoVfx = Assets.Effects.Agents.Naruto
    const _KakashiVfx = Assets.Effects.Agents.Kakashi
    const Appearance = Caster:GetAppearance()
    const BaseModel = Caster:GetModel()

    if State == 'Create' then
        const FlipTime = Args[1];
        const Cloned = Appearance:CloneModel();
        Cloned.Parent = Effects:GetParent(script.Name)
        Cloned:PivotTo(BaseModel:GetPivot())
        
        Effects:Weld(Cloned.PrimaryPart, BaseModel.PrimaryPart);
        
        ---
        local c_att, u_att = Instance.new("Attachment"), Instance.new("Attachment");
        c_att.Position, u_att.Position = vector.create(0, -0.5, 0), vector.create(0, -0.5, 0);
        c_att.Parent, u_att.Parent = BaseModel['Right Arm'], Cloned['Left Arm'];

        ----
        const LoopObj = AnimationLibrary:GetAnim("Characters.Kakashi.Abilities.Special.Raiden.Right");
        const FlipObj = AnimationLibrary:GetAnim("Characters.Kakashi.Abilities.Special.Raiden.FlipR");
        local Track = AnimationLibrary:Play(Cloned, FlipObj, 0);

        const At = CFrame.lookAlong(Cloned:FindFirstChild('Torso').Position, Caster:GetPivot().LookVector)
        const SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb)
        SmokeEffect:PivotTo(At);
        Effects:Emit(SmokeEffect);

        const ThunderFolder = Instance.new("Folder");
        ThunderFolder.Parent = Effects:GetParent(script.Name)

        const Thread = task.delay(FlipTime, function()
            Track:Stop(0.15);
            Track = AnimationLibrary:Play(Cloned, LoopObj);
        end)

        const BoltCount = NumberRange.new(5, 9)
        const Radius = NumberRange.new(0.25, 0.5)
        const LightningThread = task.delay(FlipTime - 0.1, function()
            
            while task.wait(1 / 24) do
                const Side = math.random(1, 2) == 1;
                Effects:CreateLightningBolt({
                    A1Instance = Side and c_att or u_att,
                    A0Instance = Side and u_att or c_att,
                    Color3 = Color3.fromRGB(112, 150, 255),
                    SubpartColor = Color3.fromRGB(51, 78, 255),
                    BoltCount = BoltCount,
                    CurveSize = 2,
                    Radius = Radius,
                    Parent = ThunderFolder,
                })
            end
        end)

        ---
        Cache[Caster] = function()
            Effects:CleanUp(Thread)
            Effects:CleanUp(LightningThread)
            Effects:CleanUp(ThunderFolder)

            const Torso = Cloned:FindFirstChild('Torso')
            if Torso then
                const At = CFrame.lookAlong(Torso.Position, Caster:GetPivot().LookVector)
                const SmokeEffect = Effects:Create(NarutoVfx.SmokeBomb)
                SmokeEffect:PivotTo(At);
                Effects:Emit(SmokeEffect);
            end

            for _, v in Cloned:GetDescendants() do
                if v:IsA('Decal') or v:IsA('BasePart') or v:IsA('Texture') then
                    v.Transparency = 1;
                end
            end

            Effects:CleanUp(Cloned, 1)
        end
    elseif State == 'Delete' then
        Effects:CleanUp(Cache[Caster])
    end
end