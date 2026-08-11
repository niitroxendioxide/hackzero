--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Modules = ServerStorage.Modules

local Enemies = require(ReplicatedStorage.Modules.Shared.Libraries.Enemies)
local MikuGameplayController = require(script.Parent.MikuGameplayController)
local AbilityService = require(Modules.Services.Combat.AbilityService)
local Agents = require(Modules.Libraries.Agents)

--local Enemies = require(Shared.Libraries.Enemies)
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

	local OrbBuffs = Ability:FromData("OrbBuffs")
	local Hitboxes = {}
	local Id = 0
	local NextAssist = os.clock()
	local function SpawnOrbs()
		local Params = OverlapParams.new()
		Params.FilterDescendantsInstances = {}
		Params.FilterType = Enum.RaycastFilterType.Include

		local Clock = os.clock()
		while Caster:GetState() == 'Attacking' and Caster:HasTag("MIKU_ASSIST_MODE") do
			local _ = task.wait(1 / 24)

			if (os.clock() - NextAssist) > Ability:FromData('Assist_Frequency') then
				NextAssist = os.clock()
				if TargetId == nil then
					TargetId = Enemies:GetNearestEnemy(Caster:GetPivot().Position, 75, true)
				end

				
				local ActiveAgent = Agents:GetCurrentActive(Caster.__Player_Assigned:GetAttribute('ReplicationId'))

				AbilityService:PromptAssist(ActiveAgent, 2.75, TargetId, nil, Caster)
			end

			for i = #Hitboxes, 1, -1 do
				-- calculate any user going inside this hitbox
				local Hitbox = Hitboxes[i]
				local Position = Hitbox[1]
				local Time = Hitbox[2]
				local HitboxId = Hitbox[3]

				local ReverseLookup, AgentHitboxes = Agents:GetActiveAgentsHitboxes()
				Params.FilterDescendantsInstances = AgentHitboxes

				local Remove = (os.clock() - Time) > 10 
				local HitboxHits = workspace:GetPartBoundsInBox(Position, vector.create(5, 5, 5), Params)
				local HitBuff = false
				for _, Object in HitboxHits do
					local Agent = ReverseLookup[Object]

					for _, Buff in OrbBuffs do
						HitBuff = true

						if Agent:GetEffect(Buff.Tag) then
							Agent:RefreshEffect(Buff.Tag)
							continue
						end
						
						Agent:AddEffect(Buff)
					end
				end
				
				if Remove or HitBuff then

					Ability:Effect("Miku_MusicOrb", {HitboxId, false, HitBuff}, true)

					table.remove(Hitboxes, i)
				end
			end
			
			if (os.clock() - Clock) >= 2.25 then
				Clock = os.clock()

				local Offset = CFrame.new(Random.new():NextNumber(-30, 30), 0, Random.new():NextNumber(-30, 30))
				local CasterPos = Caster:GetPivot() * Offset

				Id += 1
				local HitboxObj = {
					CasterPos,
					os.clock(),
					Id,
				}
				
				table.insert(Hitboxes, HitboxObj)

				Ability:Effect("Miku_MusicOrb", {HitboxObj[3], true, CasterPos}, true)
			end
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
					AbilityService:PromptAssist(ActiveAgent, 2.75, TargetId, nil, Caster)
				end

				for _, Buff in {StrengthBuff, DefenseBuff} do
					if Agent:GetEffect(Buff.Tag) then
						continue
					end

					Agent:AddEffect(Buff)
				end
			end)
		end},

		{1, function()
			task.spawn(SpawnOrbs)
		end},
	})
end

return Ability
