--
local Types = require("../../Types/Stages")


--
return {
    Name = "Earth",
    Map = "Dragon Ball/Destroyed West City",

    Acts = {
        Intro = {
            Requisites = {},

            Rewards = {
                Items = {
                    {
                        Type = "Item",
                        Amount = 1,
                    },
                },

                Handler = function(CompletionState): Types.Rating
                    local Survivors = CompletionState.Rescued_All_Survivors == true and 1 or 0
                    local AllEnemies = CompletionState.Beat_All_Enemies == true and 1 or 0

                    if Survivors and AllEnemies then
                        return 'S'
                    elseif Survivors or AllEnemies then
                        return 'A'
                    end

                    return 'X'
                end,
            },

            Markers = {
                ['FightArea'] = {
                    Type = 'Trigger',
                    Name = 'Spawn_Area',
                },

                ['FightArea1'] = {
                    Type = 'Trigger',
                    Name = 'Harder_Area',
                },

                ['FightArea2'] = {
                    Type = 'Trigger',
                    Name = 'Inbetween_Area',
                },

                ['FightArea3'] = {
                    Type = 'Trigger',
                    Name = 'Last_Area',
                },

                ['CrystalDestructible'] = {
                    Type = "Destructible",
                    Destructible_Id = "Crystals",
                },

                ['DestructibleWall'] = {
                    Type = "Destructible",
                    Destructible_Id = "Reinforced_Wall",
                    Broken = {
                        PlayCutscene = 'CutsceneWhenWallBreaks',
                    },
                },

                ['RefugeeNPC1'] = {
                    Type = "NPC",
                    Dialogue = {
                        {
                            Speaker = "Refugee",
                            Text = "H-hello... can I help you?",
                            Options = {
                                "I'm here to save you guys"
                            },
                        },

                        {
                            Speaker = "Refugee",
                            Text = "Oh.. you\'re chill? :D",

                            Options = {
                                "Yeah!",
                                "Maybe."
                            },
                        },

                        {
                            Speaker = "Refugee",
                            Text = "Thanks for helping. Please tell my friend over there to follow us too"
                        }
                    },
                },

                ['RefugeeNPC2'] = {
                    Type = "NPC",
                    Dialogue = {
                        {
                            Speaker = "Refugee",
                            Text = "PLEASE DO NOT HURT ME :C",
                            NextDialogue = 3,
                        },

                        {
                            Speaker = "Refugee",
                            Text = "Huh.. Oh, you want me to follow you?",
                        },

                        {
                            Speaker = "Happy Refugee",
                            Text = "Understood",
                            NextDialogue = 1.25,
                        }
                    },
                },
            },

            Guide = {
                Begin = {
                    Objective = "Rescue all the survivors",
                    Goal = {Rescued = true},
                    Enemies = {},
                    Global = true,

                    Finished = function(State)
                        return "End"
                    end
                },

                Spawn_Area = {
                    Objective = "Defeat {objective[KillEnemies]} enemies",
                    Goal = {
                        ['KillEnemies'] = 6,
                    },
                    Dialogue = {{
                        Speaker = "Agency",
                        Text = "Who are these guys?!",
                        NextDialogue = 4,
                    }, {
                        Speaker = "Agency",
                        Text = "Could it be that someone has altered this timeline?",
                        NextDialogue = 4,
                    }, {
                        Speaker = "Agency",
                        Text = "Why would they want to mess with this already desolated place?",
                        NextDialogue = 4,
                    }},
                    Enemies = {
                        [1] = {'Saiyan', 3, 1},
                        [2] = {'Saiyan', 3, 1},
                    },

                    Finished = function()
                        return 'None'
                    end
                },

                Harder_Area = {
                    Objective = "Defeat the {objective[KillEnemies]} saiyans",
                    Goal = {
                        ['KillEnemies'] = 7,
                    },
                    Enemies = {
                        [1] = {'Saiyan', 3, 3},
                        [2] = {'Saiyan', 4, 3},
                    },

                    Finished = function()
                        return 'None'
                    end
                },

                Inbetween_Area = {
                    Objective = "These should be the last enemies",
                    Goal = {
                        ['KillEnemies'] = 5,
                    },
                    Enemies = {
                        [1] = {'Saiyan', 5, 2},
                    },

                    Finished = function()
                        return 'None'
                    end
                },

                Last_Area = {
                    Objective = "Defeat their boss!",
                    Goal = {
                        ['KillEnemies'] = 1,
                    },
                    Enemies = {
                        [1] = {'Boss', 1, 1},
                    },

                    Finished = function()
                        return 'None'
                    end
                },
            },
        },
    }
} :: Types.Stage