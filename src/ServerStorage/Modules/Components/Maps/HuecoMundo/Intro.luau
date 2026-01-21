
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local DestructibleService = require(Services.Match.DestructibleService)
local GameEnum = require(Shared.GameEnum)
local StageClass = require(Classes.Game.Stage)

local HuecoMundoIntro = StageClass.new()

HuecoMundoIntro:AddHook(GameEnum.StageHook.Begin, function() 
    print("I hook the beginning of the mission!")
end)


--- Runs when the trigger is created
HuecoMundoIntro:ForTrigger("Room_1", function(Trigger: BasePart)
    print(Trigger)
    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(-15, -1, 15))
    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(24, -1, 8))
end)

HuecoMundoIntro:ForTrigger("Room_2", function(Trigger: BasePart)
    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(-24, -1, 24))
    DestructibleService:Create("Crystals", Trigger.CFrame * CFrame.new(24, -1, 24))
end)

return HuecoMundoIntro
















