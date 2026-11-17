local ReplicatedStorage = game:GetService("ReplicatedStorage")

--const Assets = ReplicatedStorage.Assets

const EnemiesLib = require("@game/ReplicatedStorage/Modules/Shared/Libraries/Enemies")
--const Animation = require("@game/ReplicatedStorage/Modules/Client/Libraries/Animation")
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
const KnightmareCache = require("@game/ReplicatedStorage/Modules/Client/Packages/KnightmareCache")

const ElementColors = {
    ['Wind'] = Color3.fromRGB(95, 255, 46),
    ['Ice'] = Color3.fromRGB(108, 196, 255),
    ['Water'] = Color3.fromRGB(26, 60, 255),
    ['Electric'] = Color3.fromRGB(75, 87, 255),
    ['Fire'] = Color3.fromRGB(255, 70, 24),
    ['Earth'] = Color3.fromRGB(121, 88, 48),
    ['Energy'] = Color3.fromRGB(54, 42, 121),
    ['Antimatter'] = Color3.fromRGB(114, 43, 121),
    ['Physical'] = Color3.fromRGB(171, 103, 54),
}

return function(...)
    const Args = {...}

    const Id = Args[1]
    const ElementId = Args[2]
    const TargetId = Args[3]
        
    const Element = GameEnum.KeyLookup(GameEnum.Afflictions, ElementId)
    const Color = (ElementColors[Element] or ElementColors.Physical) :: Color3;
    const KnightmareObj = KnightmareCache[Id]

    if KnightmareObj then
        const EnemyObject = EnemiesLib:GetEnemy(TargetId);
        const KnightmareModel = KnightmareObj.Model;
        const Vxz = vector.create(1, 0, 1)
        const Pos = KnightmareModel:GetPivot().Position
        const EPos = EnemyObject:GetPivot().Position
        const At = CFrame.lookAlong(Pos, CFrame.lookAt(Pos * Vxz, EPos * Vxz).LookVector)

        if KnightmareModel == nil or not KnightmareModel:IsDescendantOf(workspace) or KnightmareModel:FindFirstChild("RootPart") == nil then
            return;
        end

        const Gun = KnightmareModel.RootPart:FindFirstChild("Gun", true);
        Effects:Tween(KnightmareModel.RootPart, {0.2, 'Quad'}, {CFrame = At})

        for _, Vfx in Gun.Att:GetDescendants() do
            if Vfx:IsA('ParticleEmitter') then
                if Vfx:HasTag('Recolorable') then
                    Vfx.Color = ColorSequence.new(Color)
                end
                Effects:Emit(Vfx, true)
            end
        end
    end
end
