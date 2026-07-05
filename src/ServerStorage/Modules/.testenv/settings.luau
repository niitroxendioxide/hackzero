return table.freeze({
    REPLICATE_CONSTANTS = {
        HITBOXES = false,
        MARKERS = false,
    },

    MISSION = {
        --- Types: ChaosControl, Mission, Expedition
        TYPE = 'Mission',
        STAGE = {
            --- LeafVillage, Training, Testing, DailyImprovement, DungeonEx, HuecoMundo
            Stage = 'LeafVillage',
            Act = 'Intro',
        },
        DATA = {
            MissionId = 'LeafVillage_P01',
            Difficulty = 'EASY',
            --[[ChaosControlData = {
                Type = 'DailyImprovement',
                Node = 1,
            },
            AgentBuffs = {},
            Completion = {
                Experience = 1000,
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
                    {Amount = 6, Level = 50, Name = 'Sorcerer'}
                },
            },]]
        }--]]
    },

    FILL_ULT_BAR = true,


    --- PASSIVE, EASY, MEDIUM, HARD, EXTREME
    DIFFICULTY = 'EASY', 
    USE_BORROW = true, -- whether to replace agents with lvl 60 max
    BORROWED_AGENT_LEVEL = 60,

    TEST_AGENTS = {
        'Goku',
        'Chihiro',
        'Miku',
    },
})