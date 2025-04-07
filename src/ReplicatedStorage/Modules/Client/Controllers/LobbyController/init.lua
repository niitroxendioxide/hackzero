--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local AreaClass = require(Client.Classes.Area)

--
local AreaFolder: Folder;

local Controller = {
    __Cached = {} :: {{OnEnter: () -> (), OnLeave: () -> ()}},
    __AreaCache = {},
}

function Controller:Init(): ()
    Controller:RequireModules()

    AreaFolder = (workspace:WaitForChild("World"):WaitForChild("Zones", 15) :: Folder)
    if not AreaFolder then
        return
    end

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