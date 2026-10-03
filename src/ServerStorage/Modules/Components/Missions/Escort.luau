const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const Shared = ReplicatedStorage.Modules.Shared
const Classes = ServerStorage.Modules.Classes

const GameEnum = require(Shared.GameEnum)
const StageClass = require(Classes.Game.Stage)
const MissionBuilder = require(Classes.Game.MissionBuilder)
const GameStage = StageClass.new()

GameStage:OnBuild(function(Builder: MissionBuilder.MissionBuilder)
    const Data = Builder:GetData()

    const EscortedPerson = Data.Escorted or 'Template'
    --const Enemy = Data.Enemy or DEFAULT_ENEMY
    --const Level = (Data.Enemy_Level or DEFAULT_LEVEL) :: number
    --const FillerRooms = (Data.Filler_Rooms or DEFAULT_FILLER_ROOMS) :: number

    Builder:SetBeginEvent({
        Objective = `Help {EscortedPerson} leave this place.`,
        Goal = {},
        Enemies = {},
        Dialogue = {{
            Speaker = "Agency",
            Text = `I'll guide you to the correct path, just make sure {EscortedPerson} isn't hurt.`,
            NextDialogue = 2.75,
        }, {
            Speaker = "Agency",
            Text = "There's some agressive anima up ahead, so beware.",
            NextDialogue = 2.75,
        }},
        Global = true,
        Finished = 'None',
    })
end)

return GameStage
