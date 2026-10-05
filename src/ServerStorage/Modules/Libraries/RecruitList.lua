--[[
	Every recruit standing on the server, by id. RecruitService adds and removes them, the
	hitbox library and enemy targeting read from here, the same split as StructureList.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Types = require(Shared.Types.Recruits)

--
local List = {
	__Stored = {} :: {[number]: Types.ServerRecruitClass},
}

function List:Add(Recruit: Types.ServerRecruitClass)
	List.__Stored[Recruit:GetId()] = Recruit
end

function List:Remove(Recruit: Types.ServerRecruitClass)
	if List.__Stored[Recruit:GetId()] == Recruit then
		List.__Stored[Recruit:GetId()] = nil
	end
end

function List:Get(Id: number): Types.ServerRecruitClass?
	return List.__Stored[Id]
end

--- Whether `Recruit` is still standing, rather than removed since someone got hold of it.
function List:Has(Recruit: Types.ServerRecruitClass): boolean
	return List.__Stored[Recruit:GetId()] == Recruit
end

function List:GetAll(): {[number]: Types.ServerRecruitClass}
	return List.__Stored
end

function List:GetOwnedBy(Player: Player): {Types.ServerRecruitClass}
	local Owned = {}

	for _, Recruit in List.__Stored do
		if Recruit:GetOwner() == Player then
			table.insert(Owned, Recruit)
		end
	end

	return Owned
end

--- Recruits enemies may go after and hit: owned, standing and in the run.
function List:GetTargetable(): {Types.ServerRecruitClass}
	local Targetable = {}

	for _, Recruit in List.__Stored do
		if Recruit:IsActive() then
			table.insert(Targetable, Recruit)
		end
	end

	return Targetable
end

--- Hitboxes of the targetable recruits, mapped back to them.
function List:GetAllColliders(): ({[BasePart]: Types.ServerRecruitClass}, {BasePart})
	local Map, Colliders = {}, {}

	for _, Recruit in List.__Stored do
		if not Recruit:IsActive() then
			continue
		end

		local Hitbox = Recruit:GetHitbox()

		Map[Hitbox] = Recruit
		table.insert(Colliders, Hitbox)
	end

	return Map, Colliders
end

return List
