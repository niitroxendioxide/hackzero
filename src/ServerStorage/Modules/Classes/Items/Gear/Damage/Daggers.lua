local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local GearClass = require(Classes.Items.Gear)


local Object = GearClass.new('Daggers')

Object:Connect(GameEnum.GearHookType.HitDataSetup, function(Data, Context)
    Data.HitData.Damage *= 1.2
end)

return Object