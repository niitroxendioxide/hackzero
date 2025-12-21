


---
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService("Lighting")

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client

local Settings = require(ReplicatedStorage.Modules.Client.Packages.Settings)
local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)
local EffectsLib = require(Client.Libraries.Effects)


--
local Cache = {}

---
return function(
    Caster: Types.Caster
): ()
    EffectsLib:Play('Glow', Caster, {Color = Color3.new(0.960784, 0.905882, 0.121569)})

    --
    local Explosion = Effects:Create(Assets.Goku.EX_Mode.exp, 10)
    Explosion:PivotTo(Caster:GetPivot() * CFrame.new(0, -2.75, 0))

    Effects:Emit(Explosion, true)

    --
    if Cache[Caster] then
        task.cancel(Cache[Caster].Thread)
        Cache[Caster].Thread = task.delay(3, function()
            Effects:Toggle(Cache[Caster].Object, false)

            Cache[Caster] = nil
        end)

        return;
    end

    Cache[Caster] = {}
    
    local SSJ2BuffAura = Assets.Goku.SSj2Buff:Clone()
    Effects:Weld(SSJ2BuffAura, Caster:GetModel().PrimaryPart)
    SSJ2BuffAura:PivotTo(Caster:GetModel():GetPivot())
    SSJ2BuffAura.Parent = workspace.World.Effects
    Caster.__Character.__Appearance:BindParticles(SSJ2BuffAura)

    if not Settings:Get("AuraEffects", 'Graphics') then
        Effects:Toggle(SSJ2BuffAura.Aura, false)
    end

    Cache[Caster].Object = SSJ2BuffAura
    Cache[Caster].Thread = task.delay(3, function()
        Caster.__Character.__Appearance:UnbindObject(SSJ2BuffAura)
        Effects:Toggle(SSJ2BuffAura, false)
        Effects:CleanUp(SSJ2BuffAura, 1)

        Cache[Caster] = nil
    end)
end