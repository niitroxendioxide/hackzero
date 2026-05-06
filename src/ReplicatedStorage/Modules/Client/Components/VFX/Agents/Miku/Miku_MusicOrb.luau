---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Assets = ReplicatedStorage.Assets.Effects.Agents
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types.Abilities)
local Effects = require(Shared.Utility.Effects)

---
local Cache = {} :: { [number]: { Model: Model, Thread: thread } }

function Destroy(Id: number, PlayEffect: boolean?)
    local MikuAssets = Assets.Miku

    local ExistingCacheObject = Cache[Id]
    if not ExistingCacheObject then
        return
    end

    local Model = ExistingCacheObject.Model
    local Pivot = Model:GetPivot()

    if not PlayEffect then
        Effects:TweenModel(Model, 0.001, 0.3, 'Quad')
        Effects:CleanUp(Model, 0.3)
    else
        local PickupVfx = Effects:Create(MikuAssets.OrbPickup, 2.5)
        PickupVfx:PivotTo(Pivot)

        Effects:Emit(PickupVfx, true)

        Model:Destroy()
    end

    Cache[Id] = nil
    
    if coroutine.running() ~= ExistingCacheObject.Thread then
        task.cancel(ExistingCacheObject.Thread)
    end
end

return function(
    Id: number,
    State: boolean,
    Offset: CFrame?
): ()
    local MikuAssets = Assets.Miku
    
    if State == true then
        Destroy(Id,  false)

        local MikuOrb = Effects:Create(MikuAssets.MikuMusicOrb)
        MikuOrb:ScaleTo(0.001)
        MikuOrb:PivotTo(Offset)

        Effects:TweenModel(MikuOrb, 1, 0.25, 'Back')

        Cache[Id] = {
            Model = MikuOrb,
            Thread = task.delay(10, Destroy, Id, false)
        }
    elseif State == false then
        Destroy(Id, Offset)
    end
end