local ReplicatedStorage = game:GetService("ReplicatedStorage")
--
local GameEnum = require(ReplicatedStorage.Modules.Shared.GameEnum)
local Types = require("../../Types/Stages")


--
return {
    Name = "Training",
    Map = "General/Training",

    Acts = {
        Intro = {
            Description = "",
            Requisites = {},

            Completion = {
                Rewards = {
                    ['S'] = {
                        {Type = "Gold", Amount = 5000},
                        {Type = "Gems", Amount = 20},
                    },

                    ['A'] = {
                        {Type = "Gold", Amount = 2500}
                    },
                },

                Handler = function(Objectives): Types.Rating
                    if Objectives.Main == true then
                        return "S"
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
                    Design = GameEnum.Interactables.Chests.Default,
                    ItemList = {
                        {Type = "Gold", Amount = 2500},
                        {Type = "Artifact", Amount = 1, Extra = {
                            Name = "Sharingan",
                        }},
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
                    EnemyBuffs = {
                        {'Max_Health', "25000%"},
                        {'Defense', "200%"},
                    },
                    Enemies = {
                        [1] = {
                            --{Name = "Sorcerer", Amount = 1, Level = 60,}
                        } --"Dazed", 1, 60}
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
        },
    },

    Survival = {
        Easy = {
            Maximum_Waves = 5,

        },
        Infinite = {},
        
    }
} :: Types.Stage