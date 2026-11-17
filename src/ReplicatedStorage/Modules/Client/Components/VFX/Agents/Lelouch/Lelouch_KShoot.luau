local ReplicatedStorage = game:GetService("ReplicatedStorage")

--const Assets = ReplicatedStorage.Assets

const EnemiesLib = require("@game/ReplicatedStorage/Modules/Shared/Libraries/Enemies")
--const Animation = require("@game/ReplicatedStorage/Modules/Client/Libraries/Animation")
const Effects = require("@game/ReplicatedStorage/Modules/Shared/Utility/Effects")
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
const KnightmareCache = require("@game/ReplicatedStorage/Modules/Client/Packages/KnightmareCache")
const VFXLib = require("@game/ReplicatedStorage/Modules/Client/Libraries/Effects")

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

const TORSO_YAW_OFFSET = math.rad(-26.2)

-- Average hue (degrees) of the colored emitters in General.Combat.SmallHit (they range 12°-42°, orange).
-- Each element's hit gets shifted by (element hue - this) so it matches the muzzle color.
const SMALL_HIT_BASE_HUE = 28

const HitEffectData = {} :: {[string]: {Emitter: string, HueShift: number}}
for Element, ElementColor in ElementColors do
    const Hue = ElementColor:ToHSV()
    local Shift = (Hue * 360 - SMALL_HIT_BASE_HUE) % 360
    if Shift > 180 then
        Shift -= 360 -- shortest way round the wheel
    end

    HitEffectData[Element] = {
        Emitter = "SmallHit",
        HueShift = Shift,
    }
end

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

        if KnightmareModel == nil or not KnightmareModel:IsDescendantOf(workspace) or KnightmareModel:FindFirstChild("RootPart") == nil then
            return;
        end

        const RootPart = KnightmareModel.RootPart :: BasePart;
        const Gun = RootPart:FindFirstChild("Gun", true);
        const UpperTorso = RootPart:FindFirstChild("UpperTorso") :: Bone?;

        if UpperTorso and EnemyObject then
            local Rest = UpperTorso:GetAttribute("RestCFrame") :: CFrame?
            if Rest == nil then
                Rest = UpperTorso.CFrame
                UpperTorso:SetAttribute("RestCFrame", Rest)
            end

            const Dir = RootPart.CFrame:VectorToObjectSpace(EnemyObject:GetPivot().Position - RootPart.Position)
            const Yaw = math.atan2(-Dir.X, -Dir.Z) + TORSO_YAW_OFFSET
            Effects:Tween(UpperTorso, {0.2, 'Quad'}, {
                CFrame = CFrame.new(Rest.Position) * CFrame.Angles(0, Yaw, 0) * Rest.Rotation
            })
        end

        for _, Vfx in Gun.Att:GetDescendants() do
            if Vfx:IsA('ParticleEmitter') then
                if Vfx:HasTag('Recolorable') then
                    Vfx.Color = ColorSequence.new(Color)
                end
                Effects:Emit(Vfx, true)
            end
        end

        VFXLib:Play("Hit", TargetId, HitEffectData[Element] or HitEffectData.Physical)
    end
end
