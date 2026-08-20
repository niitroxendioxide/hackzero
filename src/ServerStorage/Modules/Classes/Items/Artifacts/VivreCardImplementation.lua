local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Classes = ServerStorage.Modules.Classes
local Shared = ReplicatedStorage.Modules.Shared

local GameEnum = require(Shared.GameEnum)
local ArtifactClass = require(Classes.Items.Artifact)

local ArtifactObject = ArtifactClass.new('VivreCard')
local Threads = {}

ArtifactObject:OnEvent(GameEnum.ArtifactEvents.AgentHurt, function(Data, PieceCount: number)
	if PieceCount < 4 then
		return
	end

	local Caster = Data.Agent
	local WillEffect = Caster:GetEffect('Will')
	if WillEffect then
		local WouldBeRemoved = (WillEffect.Amount - 3) <= 0

		Caster:ChangeEffect('Will', -3, true)
		if WouldBeRemoved and Threads[Caster] then
			task.cancel(Threads[Caster])
		end

		return
	end


	if Threads[Caster] then
		return
	end

	---
	WillEffect = Caster:AddEffect({
		Tag = 'Will',
		Time = 30,
		Type = 'Attack',
		Value = "2%",
		Limit = 15,
	})

	Threads[Caster] = task.spawn(function()
		while task.wait(3) do
			WillEffect = Caster:GetEffect('Will')
			if not WillEffect then
				break
			end

			if WillEffect.Amount < 15 then
				Caster:ChangeEffect('Will', 1, true)
			else
				break
			end
		end

		Threads[Caster] = nil
	end)
end)

return ArtifactObject
