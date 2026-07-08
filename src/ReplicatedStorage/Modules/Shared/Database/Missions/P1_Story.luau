return {
    ['LeafVillage_P01'] = {
        Display_Name = "Overwhelming Anima in the Leaf",
        Description = 'There seems to be an anomaly on the leaf village, I was tasked with investigating and taking care of any possible problem. I heard there might be a Relic worth recovering.',
        Recommended_Level = 1,

        Stage_Act = 'LeafVillage/Intro',
        Difficulty = 'EASY',

        Destructibles = {
            ['CrateLoot'] = {
                Drops = {
                    {Type = "Gold", Amount = 3000},
                    {Type = 'Artifact', Amount = 1, Extra = {
                        Name = "Scroll",
                    }}
                },
                SetValues = {
                    ['Recover_Lost_Relic'] = true
                },
            },

            ['CrateGold'] = {
                Drops = {
                    {Type = "Gold", Amount = 750},
                },
                SetValues = {
                    ['Crates_Broken+'] = 1
                },
            },
        },
        Triggers = {
            Begin = {
                Objective = "Find the cause for all this anima",
                Goal = {
                    Investigate_The_Area = false,
                },
                Enemies = {},
                Dialogue = {{
                    Speaker = "Agency",
                    Text = "There's unusual levels of Anima flowing through the area...",
                    NextDialogue = 3,
                },{
                    Speaker = "Agency",
                    Text = "What sort of scenario could've caused this?",
                    NextDialogue = 3,
                },},
                Global = true,

                Finished = 'None',
            },

            GrassArea = {
                Objective = "Stop the Anima-affected bandits {objective[KillEnemies]}/5",
                Goal = {
                    ['KillEnemies'] = 4,
                },
                Enemies = {
                    [1] = {
                        {Name = 'SandShinobi', Level = 1, Amount = 2, Affected_Aura = true},
                        {Name = 'SandShinobi', Level = 3, Amount = 2, Affected_Aura = true}
                    }
                },
                Dialogue = {{
                    Speaker = "Agency",
                    Text = "These guys... they're heavily affected by Anima... what is going on?!",
                    NextDialogue = 3,
                }},
                Global = true,

                Finished = 'None',
            },

            Cross = {
                Objective = "",
                Goal = {},
                Dialogue = {{
                    Speaker = 'Agency',
                    Text = 'So it seems someone\'s messing with Orochimaru\'s strength, look at the disaster he has caused over the city. ',
                    NextDialogue = 5,
                }},
                Global = true,

                Finished = "End"
            },

            Entrance = {
                Objective = "Stop the Anima-affected bandits {objective[KillEnemies]}/5",
                Goal = {
                    ['KillEnemies'] = 10,
                },
                Enemies = {
                    [1] = {
                        {Name = 'SandShinobi', Level = 1, Amount = 2, Affected_Aura = true},
                        {Name = 'SandShinobi', Level = 3, Amount = 3, Affected_Aura = true}
                    },

                    [2] = {
                        {Name = 'SandShinobi', Level = 3, Amount = 4, Affected_Aura = true},
                        {Name = 'SandShinobi', Level = 6, Amount = 1, Affected_Aura = true}
                    }
                },
                Dialogue = {{
                    Speaker = "Agency",
                    Text = "There's even more?!",
                    NextDialogue = 3,
                }},
                Global = true,

                Finished = 'None',
            },
        },
        Completion = {
            Experience = 1250,
            Rewards = {
                ['S'] = {
                    {Type = 'Money', Amount = 7500},
                    {Type = 'Gems', Amount = 45},
                    {Type = 'Artifact', Amount = 1, Extra = {
                        Name = 'CorpCapsule', 
                    }}
                },

                ['A'] = {
                    {Type = 'Money', Amount = 5000},
                    {Type = 'Gems', Amount = 15},
                },

                ['B'] = {
                    {Type = 'Money', Amount = 2500},
                }
            },

            Handler = function(State: {})
                if State.Recover_Lost_Relic == true then
                    return 'S'
                end

                return 'B'
            end,
        },
    },

    ['LeafVillage_P02'] = {
        Requires = {'LeafVillage_P01'},

        Description = 'Part 2',
        Recommended_Level = 3,
        Difficulty = 'EASY',

        Stage_Act = 'LeafVillage/Intro',
    },

    ['LeafVillage_P03'] = {
        Requires = {'LeafVillage_P02'},

        Description = 'Part 3',
        Recommended_Level = 6,
        Difficulty = 'EASY',

        Stage_Act = 'LeafVillage/Intro',
    }

}