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
            Enemies = {
                [1] = {{
                    Name = 'Saiyan',
                    Level = 25,
                    Amount = 3,
                }, {
                    Name = 'Saiyan',
                    Level = 35,
                    Amount = 2,
                }},

                [2] = {{
                    Name = 'Saiyan',
                    Level = 35,
                    Amount = 3,
                }, {
                    Name = 'Saiyan',
                    Level = 40,
                    Amount = 2,
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
        'Jotaro3',
        'Tanjiro',
    },
})