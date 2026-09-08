---
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Shared = ReplicatedStorage.Modules.Shared

const TaskTypes = require(Shared.Types.Tasks)
const EnemyDB = require(Shared.Database.Enemies)
const WorldDB = require(Shared.Database.Stages)
const Math = require(Shared.Utility.Math)

---
const NAME_LIST = {
    'John', 'Jerry', 'James', 'Jamal', 'Jamie', 'Nathan', 'Ethan', 'Mug', 'Kata', 'Bat', 'Zaros', 'Tro\'fi', 'Nitrogen', 'Helium', 'Carbonate', 'Joku',
    'Juan', 'Ramiro', 'Fred', 'Esteban', 'Nacho', 'Joaquin', 'Pedro', 'Peter', 'Unc', 'Skibidi'
};

---
const Generator = {}

function Generator.ForDialogue(Info: TaskTypes.AgencyTaskMission)
    if Info.Type == "Escort" then
        return `help me investigate {Info.World}? I'm trying to find new information about their universe and its laws`
    elseif Info.Type == "Recover" then
        return `help me get back my {Info.Item}? I believe I might've lost it when investigating Anima-Anomalies in {Info.World}`
    elseif Info.Type == "Revenge" then
        const EnemyInformation = (Info.Character and EnemyDB:GetEnemyData(Info.Character))

        return `beat '{EnemyInformation.Display_Name}'? They should be currently in {Info.World}, due to a human-anima perception, which is causing issues in their world.`
    else
        return "IMPOSSIBLE_OUTCOME<FAILURE_TYPE = \"NPC_FAILURE\">"
    end
end

function Generator.GetNameForSeed(Seed: string)
    local Generator = Random.new(Math:ToSeedNumber(Seed or '1'))
    local AgentName = NAME_LIST[Generator:NextInteger(1, #NAME_LIST)]

    return AgentName
end

function Generator.ForMissionTitle(Info: TaskTypes.AgencyTaskMission)
    const AgentName = Generator.GetNameForSeed(Info.Seed);

    if Info.Type == "Escort" then
        return `Agent {AgentName}'s Investigation`
    elseif Info.Type == "Revenge" then
        return `Agent {AgentName}'s Revenge`
    elseif Info.Type == "Recover" then
        return `Agent {AgentName}'s lost {Info.Item}`
    end

    return `Agent {AgentName}'s task to: {Info.Type}`
end

function Generator.ForMission(Info: TaskTypes.AgencyTaskMission)
    const AgentName = Generator.GetNameForSeed(Info.Seed)
    const WorldData = WorldDB:GetStage(Info.World)

    if Info.Type == "Escort" then
        return `Assigned by Agent {AgentName}, your mission is to escort him as he takes measurements, and finishes his investigation of {Info.World}`
    elseif Info.Type == "Revenge" then
        return `Assigned by Agent {AgentName}, you must dive into {WorldData.Name} and find {Info.Character}, your task is to get rid of him, or beat him up, to make sure {AgentName} gets his revenge.`
    elseif Info.Type == "Recover" then
        return `Assigned by Agent {AgentName}, you must recover {AgentName}'s lost {Info.Item}, he believes it must be somewhere around {Info.World}`
    else
        return `Assigned by [UNKNOWN], [PROCEDURE] <INFORMATION_FAILURE = [ERROR_LEVEL="HIGH", TERMINATED<State: true, Error: "Wrong Info.Type?">, REASON="UNKNOWN"]>`
    end
end

return Generator