---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared
local _Client = ReplicatedStorage.Modules.Client

local Types = require(Shared.Types.Agents)
local Effects = require(Shared.Utility.Effects)


local Cache = {}

---
return function(Caster: Types.AgentClass, State: string, ...): ()
    const _Args = {...}

    const _KakashiVfx = Assets.Effects.Agents.Kakashi
    const BaseModel = Caster:GetModel()

    if State == 'Enter' then
        local Highlight = Instance.new("Highlight")
        Highlight.DepthMode = Enum.HighlightDepthMode.Occluded;
        Highlight.OutlineColor = Color3.fromRGB(92, 163, 254)
        Highlight.FillTransparency = 1;
        Highlight.OutlineTransparency = 0.15;
        Highlight.Parent = BaseModel

        local Thread = task.spawn(function()
            while Caster:HasTag('LightningMode') do
                task.wait()
            end

            Effects:CleanUp(Cache[Caster])

        end)

        Cache[Caster] = function()
            Effects:CleanUp(Thread)
            Highlight:Destroy()    
        end
    elseif State == 'Vanish' then
        Effects:CleanUp(Cache[Caster])
    end
end