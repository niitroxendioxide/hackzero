--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local AbilityService = require(ServerStorage.Modules.Services.Combat.AbilityService)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	--
	if Caster:HasTag("MIKU_ASSIST_MODE") then
		Caster:RemoveTag("MIKU_ASSIST_MODE")

		return
	end
	
	
	
	--
	local TargetId = Context.Target and Context.Target:GetId()
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name);

	Ability:Begin(Caster, {
		{0, function()
			Caster:AddTag("MIKU_ASSIST_MODE")
		end},

		{0.35, function()
			Ability:ForOtherAgents(Caster, function(Agent, Data: { IsNext: boolean })  
				if Data.IsNext then
					AbilityService:PromptAssist(Caster, 1.5, TargetId)
				end
			end)
		end},
	})
end

return Ability
