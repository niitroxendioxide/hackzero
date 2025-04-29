--
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--
local World = workspace:FindFirstChild("World")
local Client = ReplicatedStorage.Modules.Client
local Shared = ReplicatedStorage.Modules.Shared
local Classes = Client.Classes

local Types = require(Shared.Types)
local CutsceneClass = require(Classes.Cutscene)

--
local SummonCutscene = CutsceneClass.new("Summon", 10)

function SummonCutscene.Sequence(self: Types.CutsceneClass, Data: {string})
    local CharacterName = Data[1] or "Template"

    print("hello we should show:", CharacterName)

    --
    SummonCutscene:MoveCamera(World.LobbyCutscenes.SummonRoom.Used.CameraCF.CFrame)
    SummonCutscene:Wait(5)

    SummonCutscene:End()
end

return SummonCutscene