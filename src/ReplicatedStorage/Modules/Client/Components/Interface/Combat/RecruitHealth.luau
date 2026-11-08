--[[
	Hook for recruit/ally health UI. Every client recruit calls `Update` whenever its shield
	changes and `Remove` when it is gone; nothing is drawn yet. Point `Link` at your frame and
	fill in the two methods to show it.
]]
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local ComponentClass = require(Client.Classes.Interface)
local RecruitTypes = require(Shared.Types.Recruits)

local Component = ComponentClass.new(script.Name, 'HUD', {})

function Component:Link(): Instance?
	local HUD = Players.LocalPlayer.PlayerGui:FindFirstChild('PlayerHUD')

	return if HUD then HUD:FindFirstChild('RecruitHealth', true) else nil
end

--- @param Character The recruit (`GetModel`, `GetId`, `__Display_Name`...).
function Component:Update(Character: RecruitTypes.ClientRecruitClass, Max: number, Current: number)
	-- Your UI goes here.
end

function Component:Remove(Character: RecruitTypes.ClientRecruitClass)
	-- Your UI goes here.
end

return Component
