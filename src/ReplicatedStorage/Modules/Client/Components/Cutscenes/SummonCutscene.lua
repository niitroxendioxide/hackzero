--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

--
local World = workspace:FindFirstChild("World")
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Assets = ReplicatedStorage.Assets.Characters
local Classes = Client.Classes

local Inputs = require(Client.Libraries.Inputs)
local Types = require(Shared.Types)
local EffectsUtil = require(Shared.Utility.Effects)
local CutsceneClass = require(Classes.Cutscene)

--
local SummonCutscene = CutsceneClass.new("Summon", 10)

function SummonCutscene.Sequence(self: Types.CutsceneClass, Data: {string})
    local SummonRoom = World.LobbyCutscenes.SummonRoom
    local CharacterName = Data[1] or "Template"
    local ModelCharacter = Assets.Agents:FindFirstChild(CharacterName)
    if not ModelCharacter then
        ModelCharacter = Assets.Agents:FindFirstChild("Template")
    end

    --
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 12
    Blur.Parent = Lighting

    EffectsUtil:Tween(Blur, {.1, 'Quad'}, {Size = 0})
    EffectsUtil:CleanUp(Blur, .5)

    local Bloom = Instance.new("BloomEffect")
    Bloom.Size = 56
    Bloom.Intensity = 2
    Bloom.Threshold = 2
    Bloom.Parent = Lighting

    SummonCutscene:Add(task.spawn(function()
        EffectsUtil:Tween(Bloom, {.12}, {Threshold = .85})

        task.delay(.12, function()
            EffectsUtil:Tween(Bloom, {.3}, {Threshold = 2})
            EffectsUtil:CleanUp(Bloom, 1)
        end)
    end))

    --
    local Spawn = SummonRoom.Used.CharacterAppearPlace.CFrame
    local Cloned = ModelCharacter:Clone()
    Cloned:PivotTo(Spawn)
    Cloned.PrimaryPart.Anchored = true
    Cloned.Parent = World.Effects

    SummonCutscene:Add(Cloned)

    --print("hello we should show:", CharacterName)

    --
    local Base = SummonRoom.Used.CameraCF.CFrame

    if (workspace.CurrentCamera.CFrame.Position - Base.Position).Magnitude > 50 then
        SummonCutscene:MoveCamera(Base)
        SummonCutscene:SetFOV(20)
    else
        SummonCutscene:SetFOV(28)
    end

    SummonCutscene:SetFOV(35, {.3, 'Sine', 'Out'})

    local Rng = Random.new()
    local Off = CFrame.new(Rng:NextNumber(-8, 8), Rng:NextNumber(-3, 3), Rng:NextNumber(-4, 4))

    SummonCutscene:MoveCamera(CFrame.lookAt((Base * Off).Position, Spawn.Position), {.65, 'Quad', 'Out'})
    local ActiveTime = os.clock()
    Inputs:WaitFor(Enum.UserInputType.MouseButton1)

    if os.clock() - ActiveTime < .65 then
        repeat task.wait()
        until os.clock() - ActiveTime >= 0.65
    end

    SummonCutscene:End()
end

return SummonCutscene