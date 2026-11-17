local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets

const Animation = require("@game/ReplicatedStorage/Modules/Client/Libraries/Animation")
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
const Cache = require("@game/ReplicatedStorage/Modules/Client/Packages/KnightmareCache")

return function(...)
    const Args = {...}
    const Characters = Assets.Characters.Agents;
    const LelouchVFX = Assets.Effects.Agents.Lelouch;

    const Id = Args[1] :: number;
    const State = Args[2] :: number; 

    if Cache[Id] then
        Cache[Id].Cleanup()
        Cache[Id] = nil
    end

    if State == 1 then
        -- created

        const At = Args[3] :: CFrame;
        const Ground = Effects:CastMapRaycast(At.Position, vector.create(0, -250))
        
        local Coordinates = At
        if Ground then
            Coordinates = CFrame.lookAlong(Ground.Position + vector.create(0, 10.755), At.LookVector)
        end

        ---
        const Land = Animation:GetAnim("Characters.Knightmare.Movement.Landing")
        const Idle = Animation:GetAnim("Characters.Knightmare.Movement.Idle")
        
        const Model = Effects:Create(Characters.KnightmareFrame, nil, false);
        for _, k in Model:GetDescendants() do
            if k:IsA('BasePart') then
                const Transparency = k.Transparency;
                k.Transparency = 1;

                task.delay(0.15, function()
                    Effects:Tween(k, { 0.1 }, {Transparency = Transparency})
                end)
            end
        end

        Model:PivotTo(Coordinates)
        Model.Parent = workspace;

        task.delay(0.075, function()
            const LandingTrack = Animation:Play(Model, Land);
            LandingTrack.Stopped:Once(function()
                Animation:Play(Model, Idle);
            end)

            task.wait(0.225)

            local Ground = Effects:CastMapRaycast(At.Position, vector.create(0, -250))
            if Ground then
                if (workspace.CurrentCamera.CFrame.Position - Ground.Position).Magnitude < 25 then
                    Effects:ShakeCamera("Hit")
                end

                const Explosion = Effects:Create(LelouchVFX.Landing, 4)
                Explosion:PivotTo(CFrame.new(Ground.Position + Ground.Normal * 2) * CFrame.Angles(0, Effects:Random(-math.pi, math.pi), 0))
                Effects:Emit(Explosion, true)

                Effects:CreateRocks(Ground, vector.create(1.95, 0.75, 1.95), {7, 9}, {6, 9}, {-13, 13})
            end
        end)

        Cache[Id] = {
            Model = Model,
            Cleanup = function()
                for _, k in Model:GetDescendants() do
                    if k:IsA('BasePart') then
                        Effects:Tween(k, { 0.3 }, {Transparency = 1})
                    end
                end
                
                Effects:CleanUp(Model, .5)
            end,
        };
    end

end
