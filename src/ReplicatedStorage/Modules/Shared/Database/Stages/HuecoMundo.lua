local Types = require(script.Parent.Parent.Parent.Types.Stages)

return {
    Name = "Las Noches",
    Map = "General/Dungeon",

    Acts = {
        Intro = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1C8160, 
                Source = 'Rooms',
                Extent = 15,
            },
            Description = "Find clues about what's shifted in the timeline",

            Markers = {
                ['Room_1'] = {Type = 'Trigger'},
                ['Room_2'] = {Type = 'Trigger'},
                ['Room_3'] = {Type = 'Trigger'},
                ['Room_4'] = {Type = 'Trigger'},
            },

            Rewards = {
                Handler = function(Objectives)
                    if Objectives.Investigated then
                        return "S"
                    end

                    return "X"
                end
            },

            Guide = {
                Begin = {
                    Objective = "Investigate the place",
                    Goal = {Investigated = true},
                    Enemies = {},
                    Global = true,

                    Finished = function(State)
                        return "End"
                    end
                },

                Room_2 = {
                    Objective = "Beat those guys up!",
                    Goal = {
                        KillEnemies = 3,
                    },

                    Enemies = {
                        [1] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 3}
                        },
                    },

                    Finished = function() end
                },

                Room_3 = {
                    Objective = "Beat those guys up!",
                    Goal = {
                        KillEnemies = 7,
                    },

                    Enemies = {
                        [1] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 1}
                        },

                        [2] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 1}
                        },

                        [3] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 2}
                        },

                        [4] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 2}
                        },

                        [5] = {
                            {Name = 'Sorcerer', Level = 70, Amount = 1}
                        },
                    },

                    Finished = function() end
                },
            }
        },

        SecondMission = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1525, 
                Source = 'Rooms',
                Extent = 19,
            },
            Description = "Investigate the place",
        },

        ThirdMission = {
            AutoGenerate = true,
            AutoGenerationData = {
                Seed = 0x1525, 
                Source = 'Rooms',
                Extent = 21,
            },
            Description = "Investigate the place",
        },
    },
} :: Types.Stage