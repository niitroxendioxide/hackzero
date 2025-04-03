--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local AreaClass = require(Client.Classes.Area)

--
local AreaFolder = workspace:WaitForChild("World"):WaitForChild("Zones")
local Controller = {
    __Cached = {} :: {{OnEnter: () -> (), OnLeave: () -> ()}},
    __AreaCache = {},
}

function Controller:Init(): ()
    Controller:RequireModules()

    if #AreaFolder:GetChildren() < 1 then
        AreaFolder.ChildAdded:Wait()
    end

    Controller.UpdateAreas()

    AreaFolder.ChildAdded:Connect(Controller.UpdateAreas)
end

function Controller.UpdateAreas()
    for _, Area in AreaFolder:GetChildren() do
        if Controller.__Cached[Area.Name] and Controller.__AreaCache[Area.Name] == nil then
            local Module = Controller.__Cached[Area.Name]
            local NewArea = AreaClass.new(Area)

            NewArea.OnEnter:Connect(Module.OnEnter)
            NewArea.OnLeave:Connect(Module.OnLeave)

            NewArea:Init()

            Controller.__AreaCache[Area.Name] = NewArea
        end
    end
end

function Controller:RequireModules(): ()
    local Children = Client.Components.Areas:GetChildren()

    for _, Module in Children do
        Controller.__Cached[Module.Name] = require(Module)
    end
end

return Controller