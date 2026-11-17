const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")

const Assets = ReplicatedStorage.Assets;

const Math = require("@game/ReplicatedStorage/Modules/Shared/Utility/Math")
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")


return function(Start: Vector3, Land: Vector3, Height: number, FlightTime: number)
    const LelouchVFX = Assets.Effects.Agents.Lelouch;
    
    const Grenade = Instance.new("Part")
    Grenade.Name = "LelouchGrenade"
    Grenade.Size = Vector3.one * 0.45
    Grenade.Color = Color3.fromRGB(62, 67, 9)
    Grenade.Material = Enum.Material.Plastic
    Grenade.Anchored = true
    Grenade.CanCollide = false
    Grenade.CanQuery = false
    Grenade.CanTouch = false
    Grenade.Shape = Enum.PartType.Ball
    Grenade.CastShadow = false
    Grenade.Position = Start
    Grenade.Parent = workspace

    local Elapsed = 0
    local Connection = nil
    Connection = RunService.Heartbeat:Connect(function(Delta)
        Elapsed += Delta

        const Alpha = math.min(Elapsed / FlightTime, 1)
        Grenade.Position = Math:GetArcPosition(Start, Land, Height, Alpha)

        if Alpha >= 1 then
            Connection:Disconnect()
            Grenade:Destroy()

            ---
            local Ground = Effects:CastMapRaycast(Grenade.Position, vector.create(0, -250))
            if Ground then
                const Explosion = Effects:Create(LelouchVFX.Explosion, 4)
                Explosion:PivotTo(CFrame.new(Ground.Position + Ground.Normal * 2) * CFrame.Angles(0, Effects:Random(-math.pi, math.pi), 0))
                Effects:Emit(Explosion, true)

                Effects:CreateRocks(Ground, vector.create(1.95, 0.75, 1.95), {9, 12}, {6, 9}, {-13, 13})
            end
        end
    end)
end
