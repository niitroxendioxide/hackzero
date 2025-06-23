local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
--
local QuestUtil = {}

function QuestUtil:Compress(QuestObject: {[string]: any})
    local NewObject = {
        Goals = QuestObject.Goals,
        Progress = QuestObject.Progress,
        Description = QuestObject.Description,
        Rewards = QuestObject.Rewards,
        Name = QuestObject.Name,
        Id = QuestObject.Id,
        Type = GameEnum.QuestTypes[QuestObject.Type],
    }

    return NewObject
end

return QuestUtil