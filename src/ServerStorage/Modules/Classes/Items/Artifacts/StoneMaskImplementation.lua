local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('StoneMask')
local UsedSkills = {}

ArtifactObject:OnHitProcess('Before', function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	if Data.Element == 'Ice' then
		local Health, Maximum = Data.Agent:GetHealth()
		local HealthPercentMultiplier = 1 - ((Health / Maximum) * 0.25)

		local RawMultiplier = 1 + ((Health / 12500) * HealthPercentMultiplier)
		local ExtraDamage = math.clamp(RawMultiplier, 1, 2.5);

		Data.Multipliers.Affliction *= ExtraDamage;
	end
end)

ArtifactObject:OnHitProcess('After', function(Data, PieceCount: number)
	if PieceCount < 4 or (Data.SkillUniqueToken == nil) or UsedSkills[Data.Agent] == Data.SkillUniqueToken then
		return;
	end

	UsedSkills[Data.Agent] = Data.SkillUniqueToken
	
	local MaxHealth = (Data.Target:GetStat('Max_Health'))
	local HalfDamageMult = math.clamp((Data.Total_Damage * 0.5) / MaxHealth, 0.0025, 0.05)
	local _, MaxCasterHp = Data.Agent:GetHealth()

	Data.Agent:Heal(HalfDamageMult * MaxCasterHp)
end)

return ArtifactObject
