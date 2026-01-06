local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Client = ReplicatedStorage.Modules.Client
--local Shared = ReplicatedStorage.Modules.Shared

local Camera = require(ReplicatedStorage.Modules.Client.Libraries.Camera)
local Effects = require(ReplicatedStorage.Modules.Shared.Utility.Effects)
local BaseClass = require(Client.Classes.Interface)
local Component = BaseClass.new("ChaosControl", "Lobby", {KeyToBind = Enum.KeyCode.L})

---
local CleanupObjects = {}


---
function Component:Link()
    local PlayerGui = Player.PlayerGui
	local HUD = PlayerGui:WaitForChild("LobbyHUD", 10) :: ScreenGui
    if not HUD then return end
	local Main = HUD:FindFirstChild("ChaosControl", true)

    return Main
end

function Component:Init()

    --
    local Main = Component:GetFrame()

    Component:BindToStateChange(function(State: boolean)  
        Main.Visible = true


        if State then
            Camera:MarkUsage("ChaosControl")

            Effects:Tween(workspace.CurrentCamera, { 0.45, 'Quint' }, { CFrame = workspace.World.LobbyCutscenes.ChaosControl.Main.CFrame })
            Effects:Tween(workspace.CurrentCamera, { 0.6, 'Back' }, { FieldOfView = 60 })
            
            Main.Return.Rotation = -90

            for _, Object in Main.Missions.List:GetChildren() do
                if not Object:IsA('Frame') then
                    continue
                end
                Object.UIScale.Scale = 0
            end
            
            Effects:Tween(Main.Background, {0.3, 'Sine'}, {BackgroundTransparency = 0.45})
            Effects:Tween(Main.Return, {0.5, 'Quart'}, {Position = UDim2.fromScale(0.137, 0.948)})
            Effects:Tween(Main.Return, {0.7, 'Back'}, {Rotation = 0})
            Effects:Tween(Main.Missions, {0.3, 'Quad'}, {Position = UDim2.fromScale(0.5, 0.886)})



            table.insert(CleanupObjects, task.delay(0.15, function()

                table.insert(CleanupObjects, Effects:Tween(Main.Missions.Nameplate.UIScale, {0.3, 'Back'}, {Scale = 1}))

                for k, Object in Main.Missions.List:GetChildren() do
                    if not Object:IsA('Frame') then
                        continue
                    end
                    table.insert(CleanupObjects, Effects:Tween(Object.UIScale, {0.4, 'Back'}, {Scale = 1}))
                    task.wait((k - 1) * 1 / 7)
                end
            end))
        else
            Camera:FreeUsage()
            
            Effects:Tween(Main.Return, {0.25, 'Quad'}, {Position = UDim2.fromScale(-0.1, 0.948)})
            Effects:Tween(Main.Return, {0.2, 'Back'}, {Rotation = -90})
            Effects:Tween(Main.Background, {0.2, 'Sine'}, {BackgroundTransparency = 1})
            Effects:Tween(Main.Missions, {0.3, 'Quad', 'In'}, {Position = UDim2.fromScale(0.5, 1.3)})
            Effects:Tween(Main.Missions.Nameplate.UIScale, {0.3, 'Quad'}, {Scale = 0})
        end
    end)

end

return Component