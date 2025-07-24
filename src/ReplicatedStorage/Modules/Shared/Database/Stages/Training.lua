--
local Types = require("../../Types/Stages")


--
return {
    Name = "Training",
    Map = "General/Training",

    Acts = {
        Intro = {
            Requisites = {},

            Rewards = {
                Items = {
                    {Type = "Gold", Amount = 1500},
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

                ['LootChest'] = {
                    Type = 'Chest',
                    Name = 'LootChest1',
                    ItemList = {
                        {Type = "Gold", Amount = 2500},
                    },
                },

                ['EndArea'] = {
                    Type = 'Trigger',
                    Name = "End",
                }
            },

            Guide = {
                Begin = {
                    Objective = "Test out new skills",
                    Goal = {ReachPlace = "End"},
                    Enemies = {
                        [1] = {"Saiyan", 1, 1}
                    },
                    Global = true,

                    Finished = function(State: Types.EventHandlerState): string
                        return "End"
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