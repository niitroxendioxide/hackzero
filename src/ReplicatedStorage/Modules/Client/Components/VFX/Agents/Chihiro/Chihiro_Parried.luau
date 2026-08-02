---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Client = ReplicatedStorage.Modules.Client
local Dir = 'Characters.Chihiro.Abilities.M1.'

local Animation = require(Client.Libraries.Animation)
local Types = require(Shared.Types.Abilities)
--local Effects = require(Shared.Utility.Effects)

return function(Caster: Types.Caster)
    if typeof(Caster) ~= 'table' or Caster:GetModel() == nil then
        print('Is nil?!', Caster)

        return
    end

    local Model = Caster:GetModel()
    local Anim = Animation:GetAnim(Dir .. ("Parried"..math.random(1, 3)) )
    local Track = Animation:Play(Model, Anim, 0, 1, 1)
    Track.Priority = Enum.AnimationPriority.Action4
end
