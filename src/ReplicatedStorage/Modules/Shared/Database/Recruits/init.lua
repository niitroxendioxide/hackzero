--[[
	Recruit kinds, one module each. `Template` holds the defaults: every other module only
	declares what differs and is merged onto it when loaded.

	A mission that wants a one-off variation does not need a module for it, it passes
	overrides to `Resolve` (RecruitService:Create does) and gets its own copy back.
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Modules.Shared.Types.Recruits)

--
local Recruits = {
	__Cache = {} :: {[string]: Types.RecruitData},
	__Ids = {} :: {string},
	__Ready = false,
}

--[[
	A fresh copy of `Base` with `Overrides` layered on, nested tables merged key by key.
	Nothing in the result is shared with either input, so a recruit can edit its own data.
]]
local function Merge(Base: {[any]: any}, Overrides: {[any]: any}?): {[any]: any}
	local Result = {}

	for Key, Value in Base do
		Result[Key] = if typeof(Value) == 'table' then Merge(Value) else Value
	end

	for Key, Value in (Overrides or {}) do
		if typeof(Value) == 'table' then
			Result[Key] = Merge(if typeof(Result[Key]) == 'table' then Result[Key] else {}, Value)
		else
			Result[Key] = Value
		end
	end

	return Result
end

function Recruits:Init()
	--- Framework inits modules in parallel, so a getter can land first and build it on demand.
	if Recruits.__Ready then
		return
	end

	Recruits.__Ready = true

	local Template = require(script.Template)

	for _, Module in script:GetChildren() do
		if not Module:IsA('ModuleScript') then
			continue
		end

		local Success, Data = pcall(require, Module)
		if not Success or typeof(Data) ~= 'table' then
			warn('Error loading recruit data for:', Module.Name, Data)

			continue
		end

		Recruits.__Cache[Module.Name] = if Module.Name == 'Template' then Data else Merge(Template, Data)

		table.insert(Recruits.__Ids, Module.Name)
	end

	table.sort(Recruits.__Ids, function(a, b)
		return a < b
	end)
end

--- Data for a kind, the Template when there is no module by that name.
function Recruits:GetData(Name: string): Types.RecruitData
	Recruits:Init()

	return Recruits.__Cache[Name] or Recruits.__Cache.Template
end

function Recruits:Has(Name: string): boolean
	Recruits:Init()

	return Recruits.__Cache[Name] ~= nil
end

--[[
	A recruit's own copy of its kind's data, with `Overrides` merged on top.

	```lua
	Recruits:Resolve('Template', { Stats = { Shield = 8 }, On_Defeat = { Fail_Mission = true } })
	```
]]
function Recruits:Resolve(Name: string, Overrides: {[string]: any}?): Types.RecruitData
	return Merge(Recruits:GetData(Name), Overrides) :: Types.RecruitData
end

function Recruits:GetId(Name: string): number?
	Recruits:Init()

	return table.find(Recruits.__Ids, Name)
end

function Recruits:FromId(Id: number): string?
	Recruits:Init()

	return Recruits.__Ids[Id]
end

return Recruits
