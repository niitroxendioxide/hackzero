---
local ReplicatedStorage = game:GetService('ReplicatedStorage')


local Assets = ReplicatedStorage.Assets
local Shared = ReplicatedStorage.Modules.Shared

local Types = require(Shared.Types)
local GameEnum = require(Shared.GameEnum)
local Effects = require(Shared.Utility.Effects)


---
return function(...: any): ()
    -- // ALL CODE PLACED HERE IS POINTLESS AND SHOULD BE REMOVED UPON CREATION OF A NEW EFFECT
    local RandomEnumValue = GameEnum.KeyLookup(GameEnum.Afflictions, 1)
    local Args: Types.List<any> = {...};

    table.insert(Args, Assets)

    Effects:CleanUp(function() end, 0.5)

    print('Packed args:', Args, 'Random value:', RandomEnumValue)
end