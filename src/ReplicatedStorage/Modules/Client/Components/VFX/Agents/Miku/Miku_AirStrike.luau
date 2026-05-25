---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local Enemies = require(Shared.Libraries.Enemies)
local AnimLibrary = require(Client.Libraries.Animation)

---
local AirStrikeAssets = Assets:FindFirstChild('Miku') and Assets.Miku:FindFirstChild("AirStrike")
function GroundWave(Origin: Vector3)
    local GoalSize = Vector3.new(11.648, 11.911, 13.464)
    local WindWave = Effects:Create(AirStrikeAssets.WindWave, 1)
    WindWave.Size = GoalSize * 0.5
    WindWave.CFrame = CFrame.lookAlong(Origin, vector.create(0, -1))

    Effects:Tween(WindWave, { Effects:Random(0.4, 0.6), 'Back' }, { Size = GoalSize * Effects:Random(0.9, 1.25)})
    Effects:Tween(WindWave, { Effects:Random(0.35, 0.5) }, { Transparency = 1})
    Effects:Tween(WindWave, { Effects:Random(0.35, 0.5) }, { CFrame = WindWave.CFrame * CFrame.Angles(0, 0, Effects:Random(-math.pi / 2, math.pi / 2))})
end

function WindWaves(Origin: Vector3)
    local GoalSize = Vector3.new(11.648, 11.911, 13.464)
    local WindWave = Effects:Create(AirStrikeAssets.WindWave, 1)
    WindWave.Size = GoalSize * 0.5
    WindWave.CFrame = CFrame.lookAlong(Origin, vector.create(0, -1))

    Effects:Tween(WindWave, { Effects:Random(0.45, .75), 'Quad' }, { Size = GoalSize * Vector3.new(1, 1, 0.07) * Effects:Random(1.1, 1.75)})
    Effects:Tween(WindWave, { Effects:Random(0.45, 0.6) }, { Transparency = 1})
    Effects:Tween(WindWave, { Effects:Random(0.5, 0.8), 'Sine' }, { CFrame = WindWave.CFrame * CFrame.Angles(0, 0, Effects:Random(-math.pi / 2, math.pi / 2))})
end

function AuraCircle(Origin: Vector3)
    local Mesh = Effects:Create(AirStrikeAssets.AuraCircle, 1)
    Mesh.CFrame = CFrame.lookAlong(Origin, vector.create(0, 0, -1)) * CFrame.Angles(0, Effects:Random(-math.pi, math.pi), 0)

    Effects:Tween(Mesh, { Effects:Random(0.85, 1.15), 'Quad' }, { Size = Mesh.Size * Effects:Random(1.6, 2.25)})
    Effects:Tween(Mesh, { Effects:Random(0.25, 0.6) }, { Transparency = 1})
    Effects:Tween(Mesh, { Effects:Random(0.7, 1.1), 'Sine' }, { CFrame = Mesh.CFrame * CFrame.new(0, Effects:Random(5, 11), 0) * CFrame.Angles(0, Effects:Random(-math.pi / 2, math.pi / 2), 0)})
end
 
function HandleBeam(Origin: Vector3, Time: number, Thickness: number?)
    Thickness = Thickness or 3
    local BeamModel = Effects:Create(AirStrikeAssets.AirBeam, Time + 2)
    BeamModel:PivotTo(CFrame.new(Origin + Vector3.new(0, 1.8)))

    for _, BeamMesh in BeamModel.Beam:GetChildren() do
        local Thick = BeamMesh.Name == 'In' and 0.711 or 1
        local Size = vector.create(Thick * Thickness, Thick * Thickness, 60)
        BeamMesh.Size = vector.create(0, 0, 60)
        Effects:Tween(BeamMesh, { 0.15, 'Quart' }, {Size = Size})
    end

    local WidthPos = Thickness / 5.25
    for _, f in {BeamModel.PrimaryPart:GetChildren(), BeamModel.BeamFX:GetDescendants()} do
        for _, Child in f do
            if Child:IsA('Attachment') then
                local Pos = Child.Position * Vector3.new(WidthPos, 1, WidthPos)
                Child.Position = vector.create(0, Pos.Y, 0)
                Effects:Tween(Child, { 0.2, 'Quad' }, {Position = Pos})
            elseif Child:IsA('Beam') then
                local W0, W1 = Child.Width0, Child.Width1 
                Child.Width0 = 0
                Child.Width1 = 0
                Effects:Tween(Child, { 0.15, 'Quad' }, {Width1 = W1, Width0 = W0})
            end
        end
    end

    task.delay(Time, function()
        for _, BeamMesh in BeamModel.Beam:GetChildren() do
            local Time = (BeamMesh.Name == 'In' and 0.15 or 0.3)

            Effects:Tween(BeamMesh, { Time, 'Quad', 'In' }, {Size = vector.create(0, 0, 60)})
            Effects:CleanUp(BeamMesh, Time)
        end

        for _, f in {BeamModel.PrimaryPart:GetChildren(), BeamModel.BeamFX:GetDescendants()} do
            for _, Child in f do
                if Child:IsA('Attachment') then
                    Effects:Tween(Child, { 0.35, 'Quad', 'In' }, {Position = vector.create(0, Child.Position.Y, 0)})
                elseif Child:IsA('Beam') then
                    Effects:Tween(Child, { 0.4, 'Quad', 'In' }, {Width1 = 0, Width0 = 0})
                end
            end
        end

        Effects:Toggle(BeamModel.FX, false)
        Effects:Toggle(BeamModel.SphereFX, false)
        Effects:CleanUp(BeamModel, 1)
    end)
end

return function(
    Position: Vector3,
    Time: number
): ()


    ---
    local Origin = Position
    local Cast = Effects:CastMapRaycast(Position, vector.create(0, -1000))
    if Cast then
        Origin = Cast.Position
    end


    ---
    local GroundSpikes = Effects:Create(AirStrikeAssets.GroundShockwave, Time + 2)
    GroundSpikes.CFrame = CFrame.lookAlong(Origin, vector.create(0, 0, -1)) * CFrame.Angles(math.pi, 0, 0)
    GroundSpikes.Size = vector.zero

    ---
    local LastGroundWave = os.clock()
    local GroundSpikeTime = os.clock()
    local WindWavesTime = os.clock()
    local CircleTime = os.clock()


    --- Loop
    HandleBeam(Origin, Time)

    local ActiveTime = 0;
    while ActiveTime < Time do
        ActiveTime += Effects:Wait( 1 / 24 )

        if (os.clock() - CircleTime) > 1 / 11  then
            CircleTime = os.clock()
            AuraCircle(Origin)
        end

        if (os.clock() - GroundSpikeTime) > 1 / 16 then
            GroundSpikeTime = os.clock()

            local WidthMod = Effects:Random(0.85, 1.45)
            local HeightMod = Effects:Random(-1.2, 3)
            local NewSize = Vector3.new(9.6 * WidthMod, 3.6 + HeightMod, 9.6 * WidthMod)
            local NewCF = CFrame.new(Origin + Vector3.new(0, NewSize.Y/2, 0)) * CFrame.Angles(math.pi, Effects:Random(-math.pi, math.pi), 0)

            Effects:Tween(GroundSpikes, { 1 / 12, 'Linear' }, { CFrame = NewCF, Size = NewSize })
        end

        if (os.clock() - LastGroundWave) > 1 / 7 then
            LastGroundWave = os.clock()
            GroundWave(Origin)
        end

        if (os.clock() - WindWavesTime) > 1 / 7 then
            WindWavesTime = os.clock()
            WindWaves(Origin)
        end
    end

    Effects:Tween(GroundSpikes, { 0.25, 'Quad' }, { Transparency = 1 })
    Effects:Tween(GroundSpikes, { 0.3 }, { Size = GroundSpikes.Size + Vector3.new(1, 3, 1), Position = GroundSpikes.Position + Vector3.new(0, 1.5, 0) })

end