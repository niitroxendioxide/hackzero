---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)
local AnimLibrary = require(Client.Libraries.Animation)

---
local Cache = {}

---
local function GetCFTorso(Model: Model)
    local Torso = Model:FindFirstChild("Torso")
    local Root = Model.PrimaryPart

    local Offset = Root.CFrame:ToObjectSpace(Torso.CFrame)

    return Root:GetPivot() * CFrame.new(0, Offset.Y, 0)
end

return function(
    Caster: Types.Caster,
    State: string
): ()
    local MikuAssets = Assets.Miku
    local Model = Caster:GetModel()

    if (State == 'Activate') then
        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

        EffectsLib:Play("Miku_ToggleLeek", Caster, "Disable")

        local Stage = Effects:Create(MikuAssets.Ultimate.MikuStage)
        Stage:PivotTo(GetCFTorso(Model))

        Effects:Toggle(Stage, false)

        local Root = Stage.PrimaryPart
        local Relative = {}
        local MicSizes = {}
        local AttachmentPositions = {}
        for _, Part in Stage.Speakers:GetChildren() do
            Relative[Part] = Root.CFrame:ToObjectSpace(Part.CFrame)
            Part.CFrame = Root.CFrame
            Part.Transparency = 1

            if Part.Name == 'lB' or Part.Name == 'rB' then
                for _, Attachment in Part:GetChildren() do
                    AttachmentPositions[Attachment] = Attachment.Position
                    Attachment.Position = vector.zero
                end
            end
        end


        ---
        local RightArm = Model['Right Arm']
        local AnimObj = AnimLibrary:GetAnim('Characters.Miku.Abilities.Ultimate.MicAnim')
        local MicrophoneModel = Effects:Create(MikuAssets.Ultimate.Microphone)
        MicrophoneModel:PivotTo(RightArm:GetPivot() * CFrame.new(0, -RightArm.Size.Y/2, -RightArm.Size.Z/2) * CFrame.Angles(-math.pi / 2, 0, 0))
        Effects:Weld(MicrophoneModel.PrimaryPart, RightArm)

        local MicTrack = AnimLibrary:Play(MicrophoneModel, AnimObj)
        local AnimThread = task.delay(1.5, function()
            MicTrack:AdjustSpeed(0)
        end)

        local Highlight = Instance.new('Highlight')
        Highlight.Parent = MicrophoneModel
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded
        Highlight.FillColor = Color3.fromRGB(101, 255, 232)
        Highlight.OutlineColor = Color3.fromRGB(55, 235, 255)
        Highlight.FillTransparency = 1
        Highlight.OutlineTransparency = 1


        for _, Object in MicrophoneModel:GetDescendants() do
            if Object:IsA('BasePart') and Object.Name ~= 'HumanoidRootPart' then
                local Size = Object.Size;
                MicSizes[Object] = Size

                Object.Transparency = 1
                Object.Size*=0;
            end 
        end

        local MicOutThread = task.delay(0.15, function()
            Highlight.FillTransparency = 0
            Highlight.OutlineTransparency = 0

            for Child, Size in MicSizes do
                Child.Transparency = 0
                Effects:Tween(Child, { 0.2, 'Quad' }, {Size = Size})
            end

            task.wait(0.2)
            Effects:Tween(Highlight, { 0.25 }, {FillTransparency = 1, OutlineTransparency = 1})

            task.wait(0.25)
            Effects:Emit(MicrophoneModel.PrimaryPart, true)
        end)

        ---
        local TweenThread = task.delay(.35, function()
            Effects:Toggle(Stage, true)
            local ClockStart = os.clock();
            local Toggled = false

            while true do
                local Raw = math.min((os.clock() - ClockStart), 0.9)
                local CFVal = TweenService:GetValue(Raw / 0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                local TransVal = TweenService:GetValue(Raw / 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                if (Toggled == false) then
                    Toggled = true
                    for Attachment, Pos in AttachmentPositions do
                        Effects:Tween(Attachment, { 0.2, 'Quad' }, {Position = Pos})
                        
                        if not(Attachment.Name == 'Start') then continue end

                        Effects:Toggle(Attachment, true)
                        for _, Beam in Attachment:GetChildren() do
                            if not Beam:IsA('Beam') then continue end
                            local W0, W1 = Beam.Width0, Beam.Width1

                            Beam.Width0, Beam.Width1 = 0, 0
                            Effects:Tween(Beam, { 0.35, 'Elastic' }, {Width0 = W0, Width1 = W1})
                        end
                    end
                end

                Stage:PivotTo(GetCFTorso(Model))

                for Part, Offset in Relative do
                    local Lerp = Root.CFrame:Lerp(Root.CFrame * Offset, CFVal)
                    Part.Transparency = 1 - TransVal
                    Part.CFrame = Lerp
                end

                task.wait()
            end
        end)

        Cache[Caster] = function()
            task.cancel(TweenThread)
            task.cancel(AnimThread)
            task.cancel(MicOutThread)

            if MicTrack then
                MicTrack:AdjustSpeed(1)
            end

            task.delay(0.3, function()
                for Part in MicSizes do
                    Effects:Tween(Part, { 0.2 }, {Transparency = 1})
                end

                Effects:CleanUp(MicrophoneModel, 0.5)
            end)

            Effects:Toggle(Stage, false)
            for Part in Relative do
                Effects:Tween(Part, { 0.35 }, {Transparency = 1})
            end

            Effects:CleanUp(Stage, 2)
        end
    elseif (State == 'Deactivate') then
        if Cache[Caster] then
            Cache[Caster]()
            Cache[Caster] = nil
        end

    end

end