local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


local Shared = ReplicatedStorage.Modules.Shared
local GearTypes = require(Shared.Types.Gear)

local Gear = {
    __Cache = {}
}

function Gear:Init()
    for _, GearModule in ServerStorage.Modules.Classes.Items.Gear:GetDescendants() do
        if not GearModule:IsA('ModuleScript') then
            continue
        end

        local Success, Class = pcall(require, GearModule)

        if Success then
            Gear.__Cache[Class.__Name] = Class
        else
            warn(`Error when loading class for gear {Gear.Name}: {Class}`)
        end
    end
end

function Gear:Get(Name: string): GearTypes.GearObjectClass?
    return Gear.__Cache[Name]
end

return Gear