--
local Types = require("../../Types/Stages")


--
return {
    Name = "Training",
    Map = "General/Training", --"Dragon Ball/Namek",

    Acts = {
        Intro = {
            Description = "Training area, agents can traing their abilities or test out their new abilities. Feel free to bring anyone in for either testing out their skills or messing around with the controls.",
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

                ['NPCTest1'] = {
                    Type = "NPC",
                    Dialogue = {
                        {
                            Speaker = "Training Place NPC",
                            Text = "Hello! I am a dialogue guy... haha",
                            Options = {
                                "Buddy.",
                                "What!"
                            },
                        },

                        {
                            Speaker = "Training Place NPC",
                            Text = "So. why do you want to talk to me?",
                        },

                        {
                            Speaker = "Training Place NPC",
                            Text = "You can\'t answer lol!"
                        }
                    },
                },

                ['EndArea'] = {
                    Type = 'Trigger',
                    Name = "End",
                }
            },

            Guide = {
                Begin = {
                    Objective = "Train with your agents.",
                    Goal = {KillEnemies = 1},
                    Enemies = {
                        -- Name, Amount, Level
                        [1] = {"Strongest", 1, 60,} --"Dazed", 1, 60}
                    },
                    Dialogue = {
                        {
                            Speaker = "Agency",
                            Text = "Welcome to the training area!",
                            NextDialogue = 3,
                        },

                        {
                            Speaker = "Agency",
                            Text = "You can test out your skills here. For free!",
                        }
                    },
                    Global = true,

                    Finished = function(State: Types.EventHandlerState): string
                        return "NextStage"
                    end
                },

                End = {
                    Cutscene = "_",
                    Objective = "Cutscene test!",
                    Global = true,
                    Goal = {},
                    Enemies = {},

                    Finished = function()
                        return "End"
                    end
                },

                NextStage = {
                    Objective = "Fight against the training dummies",
                    Global = true,
                    Goal = {KillEnemies = 1},
                    Enemies = {
                        [1] = {"Strongest", 1, 60},
                    },

                    Finished = function()
                        return "NextStage"
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
                        return "End"
                    end
                }
            },
        }
    }
} :: Types.Stage