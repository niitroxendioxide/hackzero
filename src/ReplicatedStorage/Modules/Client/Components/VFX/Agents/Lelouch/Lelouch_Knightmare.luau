local ReplicatedStorage = game:GetService("ReplicatedStorage")

const Assets = ReplicatedStorage.Assets

const Animation = require("@game/ReplicatedStorage/Modules/Client/Libraries/Animation")
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
const Cache = {} 

return function(...)
    const Args = {...}
    const Characters = Assets.Characters.Agents;
    const LelouchAssets = Assets.Effects.Agents.Lelouch;

    const Id = Args[1] :: number;
    const State = Args[2] :: number; 

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
        
        const Model = Effects:Create(Characters.KnightmareFrame, 10, false);
        for _, k in Model:GetDescendants() do
            if k:IsA('BasePart') then
                const Transparency = k.Transparency;
                k.Transparency = 1;

                task.delay(0.05, function()
                    Effects:Tween(k, { 0.1 }, {Transparency = Transparency})
                end)
            end
        end

        Model:PivotTo(Coordinates)
        Model.Parent = workspace;

        const LandingTrack = Animation:Play(Model, Land);

        LandingTrack.Stopped:Once(function()
            Animation:Play(Model, Idle);
        end)

        Cache[Id] = Model;

    elseif State == 2 then
        -- deleted

        if Cache[Id] then
            Cache[Id]:Destroy();
        end
    end

end
