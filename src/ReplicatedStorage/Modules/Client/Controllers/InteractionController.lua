local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared

local Chests = require(Client.Libraries.Chests)
local Network = require(Shared.Network)
local GameEnum = require(Shared.GameEnum)

local Controller = {}

function Controller:Init()

    ProximityPromptService.PromptTriggered:Connect(function(Prompt, Player)
        if Prompt:GetAttribute("Type") == GameEnum.InteractionType.Chest then
            local ChestId = Prompt:GetAttribute("ChestId")
            local ChestObject = Chests:GetById(ChestId)
            if not ChestObject or ChestObject.Opened then
                return
            end

            Chests:SetOpenState(ChestId, true)

            Network:Fire("ChestInteraction", GameEnum.ChestInteractions.Open, ChestId)
        end

    end)

end

return Controller
