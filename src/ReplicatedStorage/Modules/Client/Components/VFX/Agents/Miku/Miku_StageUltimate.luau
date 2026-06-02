---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
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

        local Stage = Effects:Create(MikuAssets.Ultimate.MikuStage)
        Stage:PivotTo(GetCFTorso(Model))

        Effects:Toggle(Stage, true)

        local Root = Stage.PrimaryPart
        local Relative = {}
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

        local TweenThread = task.spawn(function()
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