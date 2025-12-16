--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Modules.Shared
local EffectUtil = require(Shared.Utility.Effects)
local Util = {}

local OriginalScreenTransparency = {} :: { [any] : { string | number} }

local null_func = function() end

--[[
    Hides the player HUD
    @param Time Automatically show it again after x seconds
    @return `function` ShowHUD: Shows the HUD again
]]
function Util:HideHUD(Time: number?, IgnoreDescendantOf: string?): (() -> ())?
    local Player = Players.LocalPlayer
    local Gui = Player.PlayerGui

    local HUD = Gui:FindFirstChild("PlayerHUD")
    local Screen = HUD and HUD:FindFirstChild("Screen")
    if not (HUD) or not (Screen) then
        return null_func
    end


    local DescendantToIgnore = IgnoreDescendantOf ~= nil and Screen:FindFirstChild(IgnoreDescendantOf) or Screen.Dialogues

    for _, Object in Screen:GetDescendants() do
        if Object:IsDescendantOf(Screen.Dialogues) or (Object:IsDescendantOf(DescendantToIgnore)) then
            continue
        end

        if Object:IsA("Frame") or Object:IsA("CanvasGroup") then
            if not OriginalScreenTransparency[Object] then
                OriginalScreenTransparency[Object] = {Object.BackgroundTransparency, 'BackgroundTransparency'}
            end

            EffectUtil:Tween(Object, {.25}, {BackgroundTransparency = 1})
        elseif Object:IsA("ImageLabel") or Object:IsA("ViewportFrame") then
            if not OriginalScreenTransparency[Object] then
                OriginalScreenTransparency[Object] = {Object.ImageTransparency, 'ImageTransparency'}
            end

            EffectUtil:Tween(Object, {.25}, {ImageTransparency = 1})
        elseif Object:IsA("TextLabel") then
            if not OriginalScreenTransparency[Object] then
                OriginalScreenTransparency[Object] = {Object.TextTransparency, 'TextTransparency'}
            end

            EffectUtil:Tween(Object, {.25}, {TextTransparency = 1})
        elseif Object:IsA("UIStroke") then
            if not OriginalScreenTransparency[Object] then
                OriginalScreenTransparency[Object] = {Object.Transparency, 'Transparency'}
            end

            EffectUtil:Tween(Object, {.25}, {Transparency = 1})
        end

    end

    local function Show()
        for Object, TransparencyValue in OriginalScreenTransparency do
            EffectUtil:Tween(Object, {.25}, {[TransparencyValue[2]] = TransparencyValue[1]})
        end
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