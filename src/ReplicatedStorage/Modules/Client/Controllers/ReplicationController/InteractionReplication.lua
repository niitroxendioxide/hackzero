local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Chests = require(Client.Libraries.Chests)
local NPCS = require(Client.Libraries.NPCS)
local LocalData = require(Client.Libraries.LocalData)
local StageDatabase = require(Shared.Database.Stages)
local MissionsDatabase = require(Shared.Database.Missions)
local InterfaceController = require(Client.Controllers.InterfaceController)
-- TODO: Add destructibles here too :v

--
local Controller = {}

function Controller:CreateChest(Buffer: buffer, Part: BasePart)
    local Id = buffer.readu16(Buffer, 1)
	local Design = 1--buffer.readu16(Buffer, 3)

    Chests:CreateWithBase(Part, Id, Design)
end

function Controller:CreateNPC(Buffer: buffer, Part: BasePart)

    NPCS:CreateWithBase(Part)

end

function Controller:PlayEventDialogue(Buffer: buffer)
	const Wave = buffer.readu8(Buffer, 1)
	const EventName = buffer.readstring(Buffer, 2, buffer.len(Buffer)-2)
	const AllocatedDialogueData = LocalData:GetAllocatedDialogueData()
	local EventData;

	if AllocatedDialogueData then
		EventData = AllocatedDialogueData.Events[EventName]

		if EventData == nil then
			print('Event:', EventName, 'doesn\'t exist!')
		end
	else
		local MissionData = LocalData:GetStageData()
	
		if MissionData.MissionId == nil then
			EventData = StageDatabase:GetEvent(MissionData.Stage, MissionData.Act, EventName)
		else
			local Data = MissionsDatabase:Get(MissionData.MissionId)
			EventData = Data.Triggers[EventName]
		end

	end
	local Dialogue = InterfaceController:GetComponent("Dialogue")
	--- Wave 0 is the event's own Dialogue, anything else that wave's WaveDialogue.
	const Lines = if EventData == nil then nil
		elseif Wave > 0 then (EventData.WaveDialogue or {})[Wave]
		else EventData.Dialogue

	if typeof(Lines) ~= 'table' then
		return
	end

	Dialogue:PlaySequence(Lines)
end

return Controller
