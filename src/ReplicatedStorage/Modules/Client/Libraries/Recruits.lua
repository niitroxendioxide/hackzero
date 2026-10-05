--[[
	Client copies of every recruit, by the id the server knows them by. Filled by
	EntityController, read by anything that needs to find one (enemy skill targets, UI).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types.Recruits)

--
local Recruits = {
	__Objs = {} :: {[number]: Types.ClientRecruitClass},
}

function Recruits:Add(Recruit: Types.ClientRecruitClass)
	Recruits.__Objs[Recruit:GetId()] = Recruit
end

function Recruits:Get(Id: number): Types.ClientRecruitClass?
	return Recruits.__Objs[Id]
end

--- Take it out of the registry and hand it back, so the caller can destroy it.
function Recruits:Remove(Id: number): Types.ClientRecruitClass?
	local Recruit = Recruits.__Objs[Id]
	Recruits.__Objs[Id] = nil

	return Recruit
end

function Recruits:GetAll(): {[number]: Types.ClientRecruitClass}
	return Recruits.__Objs
end

function Recruits:GetOwnedBy(Player: Player): {Types.ClientRecruitClass}
	local Owned = {}

	for _, Recruit in Recruits.__Objs do
		if Recruit:IsOwner(Player) then
			table.insert(Owned, Recruit)
		end
	end

	return Owned
end

return Recruits
