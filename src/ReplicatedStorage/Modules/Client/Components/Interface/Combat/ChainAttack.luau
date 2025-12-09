local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Modules.Client
local Interface = require(Client.Classes.Interface)

local Component = Interface.new("ChainAttack", "HUD")

local SwitchIcons = {
    Keyboard = {
        Left = 7031930012,
        Right = 7049040343,
    },

    Console = {
        Right = 114038404583831,

    }
}


function Component:Link()
    local PlayerGui = Players.LocalPlayer.PlayerGui
    local HUD = PlayerGui:WaitForChild("PlayerHUD", 10);
    if not HUD then return end;

    return HUD.Screen:WaitForChild("ChainAttack")
end


function Component:Init()
    
end

function Component:Show()

end


return Component