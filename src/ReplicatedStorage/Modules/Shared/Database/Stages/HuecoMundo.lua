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
                Extent = 100,
            },
            Description = "Find clues about what's shifted in the timeline",

            Markers = {
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
                            {Name = 'Template', Level = 3, Amount = 3}
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