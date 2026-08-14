--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Classes = ServerStorage.Modules.Classes
local Services = ServerStorage.Modules.Services

local Types = require(Shared.Types.Abilities)
local AbilityClass = require(Classes.Combat.ServerAbility)
local SasukeGameplayController = require("./SasukeGameplayController")
local AbilityService = require(Services.Combat.AbilityService)

--
local CooldownList = {}
local Ability = AbilityClass.new()

function Ability:Play(Caster: Types.ServerAgent): ()
	---
	local AssistHit = false

	Ability:Begin(Caster, {
		{0, function()
			Caster:SwitchState("Attacking", Ability:FromData("Attack_State_Time"))
		end},

		{0.25, function()
			local Projectile; Projectile = Ability:CreateMovingHitbox(Caster, Caster:GetPivot() * CFrame.new(0, 0, -1), vector.create(3, 3), 200, 1, function(Enemy)  
				local CanPromptAssist = (os.clock() - (CooldownList[Enemy] or 0)) > (RunService:IsStudio() and 0.01 or 8)
				if not(AssistHit) and CanPromptAssist then
					AssistHit = true
					CooldownList[Enemy] = os.clock()

					AbilityService:PromptAssist(Caster, 1.5, Enemy:GetId(), function()  
						Ability:Effect("Substitution", { Caster }, true)
					end)
				end
				
				SasukeGameplayController:ConnectThread(Enemy, Caster)
				Ability:Hit(Caster, Enemy, Ability:FromData("Hit", nil, Caster:GetSkillLevel(Ability.__Name)))
				
				Projectile:Destroy()
			end)
		end}
	})
end

return Ability
