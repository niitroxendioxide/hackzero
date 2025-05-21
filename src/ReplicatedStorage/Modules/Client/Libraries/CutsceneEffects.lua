--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local EffectUtil = require(Shared.Utility.Effects)
local Util = {}

--[[
    Hides the player HUD
    @param Time Automatically show it again after x seconds
    @return `function` ShowHUD: Shows the HUD again
]]
function Util:HideHUD(Time: number?): (() -> ())?
    local Player = Players.LocalPlayer
    local Gui = Player.PlayerGui

    local HUD = Gui:FindFirstChild("PlayerHUD")
    local Screen = HUD and HUD:FindFirstChild("Screen")
    if not (HUD) or not (Screen) then
        return
    end

    EffectUtil:Tween(Screen, {.25}, {GroupTransparency = 1})

    local function Show()
        EffectUtil:Tween(Screen, {.25}, {GroupTransparency = 0})
    end

    if Time then
        task.delay(Time, Show)
    end

    return Show
end


--[[
    Hides all characters that don't belong to the local player
    @param Time Automatically clear after some time
    @return `function` ShowCharacters: Shows all the characters again
]]
function Util:HideNonUserCharacters(Time: number?): () -> ()
    local function Show()
        for i = 1, 1 do
            --
        end
    end

    if Time then
        task.delay(Time, Show)
    end

    return Show
end

return Util