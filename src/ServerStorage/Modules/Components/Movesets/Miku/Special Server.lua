--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Agents = require(ServerStorage.Modules.Libraries.Agents)
local MikuGameplayController = require(script.Parent.MikuGameplayController)
local AbilityService = require(ServerStorage.Modules.Services.Combat.AbilityService)
local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local Types = require(Shared.Types.Agents)
local AbilityClass = require(Classes.Combat.ServerAbility)

--
local Ability = AbilityClass.new()

function Ability:Verify(Caster: Types.ServerAgentClass)
	if Caster:GetState() == "Attacking" and Caster:HasTag("MIKU_ASSIST_MODE") then
		return true
	end

	return Caster:GetState() == "Idle"
end

function Ability:Play(Caster: Types.ServerAgentClass, s, t, Context)
	--
	if Caster:HasTag("MIKU_ASSIST_MODE") then
		Caster:RemoveTag("MIKU_ASSIST_MODE")
		Caster:RemoveTag("CharacterStatic")
		Caster:SwitchState("Idle", 1)

		return
	end	
	
	--
	local TargetId = Context.Target and Context.Target:GetId()
	local SkillLevel = Caster:GetSkillLevel(Ability.__Name);

	local AttackerStrength = Caster:GetStat("Attack")
	local StrengthBuffMax = Ability:FromData("MaxAttackValue")
	local DefenseBuffMax = Ability:FromData("MaxDefenseValue")

	local StrengthBuffValue = math.min(Ability:FromData("StrengthBuffValue", nil, SkillLevel) * (AttackerStrength * 0.25), StrengthBuffMax);
	local DefenseBuffValue = math.min(Ability:FromData("DefenseBuffValue", nil, SkillLevel) * (AttackerStrength * 0.1), DefenseBuffMax);

	local StrengthBuff = MikuGameplayController:PackBuff(Caster, 'Attack', 30, StrengthBuffValue, Ability:FromData("StrengthBuffId"))
	local DefenseBuff = MikuGameplayController:PackBuff(Caster, 'Defense', 30, DefenseBuffValue, Ability:FromData("DefenseBuffId"))

	local function WhileActive()
		local NextAssist = os.clock()
		while Caster:HasTag('MIKU_ASSIST_MODE') do
			if (os.clock() - NextAssist) > Ability:FromData('Assist_Frequency') then
				NextAssist = os.clock()
				if TargetId == nil then
					TargetId = Enemies:GetNearestEnemy(Caster:GetPivot().Position, 75, true)
				end

				---
				local ActiveAgent = Agents:GetCurrentActive(Caster.__Player_Assigned:GetAttribute('ReplicationId'))

				AbilityService:PromptAssist(ActiveAgent, 2.75, TargetId, nil, Caster)
			end

			task.wait()
		end
	end

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", 5e12)
			Caster:AddTag("MIKU_ASSIST_MODE")
			Caster:AddTag("CharacterStatic")
		end},

		{0.35, function()
			Ability:ForOtherAgents(Caster, function(Agent, Data: { IsNext: boolean })  
				if Data.IsNext then
					local ActiveAgent = Agents:GetCurrentActive(Caster.__Player_Assigned:GetAttribute('ReplicationId'))
					AbilityService:PromptAssist(ActiveAgent, 2,75, TargetId, nil, Caster)
				end

				for _, Buff in {StrengthBuff, DefenseBuff} do
					if Agent:GetEffect(Buff.Tag) then
						continue
					end

					Agent:AddEffect(Buff)
				end
			end)
		end},

		{0.5, function()
			task.spawn(WhileActive)
		end}
	})
end

return Ability
