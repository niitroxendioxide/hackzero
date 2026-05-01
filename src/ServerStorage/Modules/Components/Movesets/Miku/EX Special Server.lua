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
			task.spawn(function()
				local Clock = os.clock()
				while Caster:GetState() == 'Attacking' and Caster:HasTag("MIKU_ASSIST_MODE") do
					local _ = task.wait(1 / 24)
					
					if (os.clock() - Clock) >= 2.25 then
						Clock = os.clock()

						local Offset = CFrame.new(Random.new():NextNumber(-30, 30), 0, Random.new():NextNumber(-30, 30))
						local CasterPos = Caster:GetPivot() * Offset

						local Box = Instance.new("Part")
						Box.Size = vector.create(4, 4, 4)
						Box.Color = Color3.fromRGB(255, 0, 0)
						Box.Transparency = 0
						Box.Material = Enum.Material.ForceField
						Box.CFrame = CasterPos
						Box.Parent = workspace

						task.delay(10, Box.Destroy, Box)
					end
				end

			end)
		end},
	})
end

return Ability
