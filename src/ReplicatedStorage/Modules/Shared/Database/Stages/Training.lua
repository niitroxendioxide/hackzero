--
local Types = require("../../Types/Stages")


--
return {
    Name = "Training",
    Map = "General/Training",

    Acts = {
        Act1 = {
            Requisites = {
                
            },

            Structures = {
                
            },

            Rewards = {
                Items = {
                    ["Gold"] = 2500,
                },

                Handler = function(Objectives): Types.Rating
                    if Objectives.Main == true then
                        return "SSS"
                    end

                    return "X"
                end
            },

            Markers = {
                ['CutsceneArea'] = {
                    Type = 'Trigger',
                    Name = 'CutsceneTest',
                },

                ['FightArea1'] = {
                    Type = 'Chest',
                    Name = 'LootChest1',
                    ItemList = {
                        ["Gold"] = 2500,
                    },
                },
            },

            Guide = {


                Begin = {
                    Objective = "Test out new skills",
                    Goal = {KillEnemies = 1},
                    Enemies = {
                        -- Enemy Name, Enemy Count, Enemy Level
                        --[1] = {"Saiyan", 1, 60}
                    },
                    Global = true,

                    Finished = function(State: Types.EventHandlerState): string
                        return "Begin"
                    end
                },

                CutsceneTest = {
                    Cutscene = "TrainingAreaTest",
                    Objective = "Cutscene test!",
                    Global = true,
                    Goal = {},
                    Enemies = {
                        [1] = {"Immortal", 1, 60},
                    },

                    Finished = function()
                        return "Begin"
                    end
                }
            },
        }
    }
} :: Types.Stage