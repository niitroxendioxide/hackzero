local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Chests = require(Client.Libraries.Chests)
local NPCS = require(Client.Libraries.NPCS)
local LocalData = require(Client.Libraries.LocalData)
local StageDatabase = require(Shared.Database.Stages)
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
	local EventName = buffer.readstring(Buffer, 1, buffer.len(Buffer)-1)

	local Stage, Act = LocalData:GetStageData()
	local EventData = StageDatabase:GetEvent(Stage, Act, EventName)

	local Dialogue = InterfaceController:GetComponent("Dialogue")

	Dialogue:PlaySequence(EventData.Dialogue)
end

return Controller
