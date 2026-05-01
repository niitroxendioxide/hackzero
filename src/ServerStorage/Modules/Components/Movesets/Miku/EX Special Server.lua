--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes

local Agents = require(ServerStorage.Modules.Libraries.Agents)
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
	local Buffs = Ability:FromData("Buffs", nil, SkillLevel)

	local OrbBuffs = Ability:FromData("OrbBuffs")
	local Hitboxes = {}
	local function SpawnOrbs()
		local Params = OverlapParams.new()
		Params.FilterDescendantsInstances = {}
		Params.FilterType = Enum.RaycastFilterType.Include

		local Clock = os.clock()
		while Caster:GetState() == 'Attacking' and Caster:HasTag("MIKU_ASSIST_MODE") do
			local _ = task.wait(1 / 24)

			for i = #Hitboxes, 1, -1 do
				-- calculate any user going inside this hitbox
				local Hitbox = Hitboxes[i]
				local Position = Hitbox[1]
				local Time = Hitbox[2]

				local ReverseLookup, AgentHitboxes = Agents:GetActiveAgentsHitboxes()
				Params.FilterDescendantsInstances = AgentHitboxes

				local Remove = (os.clock() - Time) > 10 
				local HitboxHits = workspace:GetPartBoundsInBox(Position, vector.create(5, 5, 5), Params)
				for _, Object in HitboxHits do
					local Agent = ReverseLookup[Object]

					for _, Buff in OrbBuffs do
						if Agent:GetEffect(Buff.Tag) then
							continue
						end

						Agent:AddEffect(Buff)
						Remove = true
					end
				end
				
				if Remove then
					if Hitbox[3] then
						Hitbox[3]:Destroy()
					end

					table.remove(Hitboxes, i)
				end
			end
			
			if (os.clock() - Clock) >= 2.25 then
				Clock = os.clock()

				local Offset = CFrame.new(Random.new():NextNumber(-30, 30), 0, Random.new():NextNumber(-30, 30))
				local CasterPos = Caster:GetPivot() * Offset

				local new_part = Instance.new("Part")
				new_part.Size = vector.create(4, 4, 4)
				new_part.Color = Color3.fromRGB(255)
				new_part.Transparency = 0.75
				new_part.Anchored = true
				new_part.CFrame = CasterPos
				new_part.Parent = workspace

				table.insert(Hitboxes, {
					CasterPos,
					os.clock(),
					new_part
				})
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
					AbilityService:PromptAssist(Caster, 1.5, TargetId)
				end

				for _, Buff in Buffs do
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
