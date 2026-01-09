return table.freeze({
    REPLICATE_CONSTANTS = {
        HITBOXES = false,
        MARKERS = false,
    },

    MISSION = {
        --- Types: ChaosControl, Mission
        TYPE = 'ChaosControl',
        STAGE = {
            --- Training, DailyImprovement, DungeonEx
            Stage = 'DailyImprovement',
            Act = 'Intro',
        },
        DATA = {
            AgentBuffs = {},
            Completion = {
                Rewards = {
                    ['S'] = {
                        {Type = 'Gold', Amount = 1000},
                        {Type = 'Gems', Amount = 60},
                    },
                },
            },
            Enemies = {
                [1] = {{
                    Name = 'Saiyan',
                    Level = 25,
                    Amount = 1,
                }, {
                    Name = 'Saiyan',
                    Level = 35,
                    Amount = 1,
                }},

                [2] = {{
                    Name = 'Saiyan',
                    Level = 35,
                    Amount = 1,
                }, {
                    Name = 'Saiyan',
                    Level = 40,
                    Amount = 1,
                }}
            },
        }
    },

    FILL_ULT_BAR = true,
    DIFFICULTY = 'EASY',
    USE_BORROW = true, -- whether to replace agents with your own ones
    BORROWED_AGENT_LEVEL = 60,

    TEST_AGENTS = {
        'Goku',
        'Naruto',
        'Tanjiro',
    },
})