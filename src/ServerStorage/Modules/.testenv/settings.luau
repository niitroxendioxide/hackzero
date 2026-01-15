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
            ChaosControlData = {
                Type = 'DailyImprovement',
                Node = 1,
            },
            AgentBuffs = {},
            Completion = {
                Rewards = {
                    ['S'] = {
                        {Type = 'Gold', Amount = 1000},
                        {Type = 'Gems', Amount = 60},
                        {Type = 'Artifact', Amount = 1, Extra = {
                            Name = 'CorpCapsule',
                        }}
                    },
                },
            },
            Enemies = {
                [1] = {
                    {Amount = 6, Level = 7, Name = 'Sorcerer'}
                },
                [2] = {
                    {Amount = 7, Level = 7, Name = 'Sorcerer'}
                },
                [3] = {
                    {Amount = 8, Level = 7, Name = 'Sorcerer'}
                },
                [4] = {
                    {Amount = 9, Level = 7, Name = 'Sorcerer'}
                },
                [5] = {
                    {Amount = 10, Level = 7, Name = 'Sorcerer'}
                },
                [6] = {
                    {Amount = 11, Level = 7, Name = 'Sorcerer'}
                },
                [7] = {
                    {Amount = 12, Level = 7, Name = 'Sorcerer'}
                },
                [8] = {
                    {Amount = 13, Level = 7, Name = 'Sorcerer'}
                },
                [9] = {
                    {Amount = 14, Level = 7, Name = 'Sorcerer'}
                },
            },
        }
    },

    FILL_ULT_BAR = true,


    --- PASSIVE, EASY, MEDIUM, HARD, EXTREME
    DIFFICULTY = 'MEDIUM', 
    USE_BORROW = false, -- whether to replace agents with lvl 60 max
    BORROWED_AGENT_LEVEL = 60,

    TEST_AGENTS = {
        'Goku',
        'Chihiro',
    },
})