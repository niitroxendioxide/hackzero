local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local DamageLibrary = require(ServerStorage.Modules.Libraries.Damage)
local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('PhilosophersStone')
local ArtifactInitData = {
	_started = false,
}
local MarkedEnemies = {}

---
ArtifactObject:OnHitProcess("After", function(Data, PieceCount: number): (number, number)
	if not ArtifactInitData._started then
		ArtifactInitData._started = true

		DamageLibrary.EnemyHitInner:Connect(function(Enemy, Data)
			for Caster, Enemies in MarkedEnemies do
				for _, MarkedEnemy in Enemies do
					if MarkedEnemy ~= Enemy then
						continue
					end

					local Energy = DamageLibrary:CalculateEnergyForHit(Enemy, Data.Damage) * 0.33

					Caster:GiveEnergy(Energy)
				end
			end
		end)
	end

	if PieceCount < 4 then return end

	local Caster = Data.Agent
	if Data.SkillId == GameEnum.Skills.EX_Special or Data.SkillId == GameEnum.Skills.Special then
		if MarkedEnemies[Caster] == nil then
			MarkedEnemies[Caster] = {}
		end
		
		if #MarkedEnemies[Caster] >= 5 then
			return
		end

		local HitTarget = Data.Target
		if table.find(MarkedEnemies[Caster], HitTarget) then
			return;
		end

		table.insert(MarkedEnemies[Caster], HitTarget);

		local RitualEffect = Caster:GetEffect('RitualCount')
		if RitualEffect then
			Caster:ChangeEffect('RitualCount', -1, true)
		else
			Caster:AddEffect({
				Tag = 'RitualCount',
				Limit = 5,
				Time = 10,
			})
		end

		local _ = task.spawn(function()
			local Started = os.clock()

			while (os.clock() - Started) < 10 do
				if not HitTarget:IsAlive() then
					Caster:GiveEnergy(10)

					break
				end

				task.wait()
			end

			local Index = table.find(MarkedEnemies[Caster], HitTarget);
			if Index then
				table.remove(MarkedEnemies[Caster], Index)
			end
		end)
	end
end)

return ArtifactObject
