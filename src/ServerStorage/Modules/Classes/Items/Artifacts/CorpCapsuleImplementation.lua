local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('CorpCapsule')
local UsedTokens = {}
local Threads = {}

ArtifactObject:OnHitProcess('After', function(Data, PieceCount: number)
	local Caster = Data.Agent
    if PieceCount < 4 or (Data.SkillUniqueToken == nil) or not Caster or UsedTokens[Caster] == Data.SkillUniqueToken then
		return;
	end

    UsedTokens[Caster] = Data.SkillUniqueToken

	if Data.SkillId == GameEnum.Skills.Dodge_Counter then
        local CapsuleEffect = Caster:GetEffect("DefCapsule")
        if CapsuleEffect then
            Caster:ChangeEffect("DefCapsule", 1)

            return
        end
        
        Caster:AddEffect({
            Tag = 'DefCapsule',
            Value = 15,
            Type = 'Defense',
            Limit = 8,
            Time = 45,
        })
	end
end)

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.SkillCasted, function(Data, PieceCount: number)
    if PieceCount < 4 then
        return
    end

    local Caster = Data.Agent;
    local CapsuleEffect = Caster:GetEffect("DefCapsule")
    if Threads[Caster] or not CapsuleEffect then
        return
    end


    if Data.SkillId == GameEnum.Skills.Quick_Assist then
        
        Threads[Caster] = task.spawn(function()
            local StartedTime = os.clock()

            while (os.clock() - StartedTime < 12) do
                CapsuleEffect = Caster:GetEffect("DefCapsule")
                if not CapsuleEffect or CapsuleEffect.Amount <= 0 then
                    break
                end

                local Percent = (CapsuleEffect.Amount / 6) * 1.1;
                local BaseHealth = Caster:GetHealth()
                local HealedAmount = (Percent / 100) * BaseHealth;

                Caster:Heal(HealedAmount)

                task.wait(1.5)
            end

            Threads[Caster] = nil

        end)

    end
end)

return ArtifactObject
