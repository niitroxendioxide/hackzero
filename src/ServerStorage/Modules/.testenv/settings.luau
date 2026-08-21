return table.freeze({
    REPLICATE_CONSTANTS = {
        HITBOXES = false,
        MARKERS = false,
        ENEMY_LOCATIONS = false,
    },

    MISSION = {
        --- Types: ChaosControl, Mission, Expedition
        TYPE = 'Expedition',
        STAGE = {
            --- LeafVillage, Training, Testing, DailyImprovement, DungeonEx, HuecoMundo
            Stage = 'Training',
            Act = 'Intro',
        },
        DATA = {
            --MissionId = 'LeafVillage_P01',
            --Difficulty = 'EASY',
            ChaosControlData = {
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
                    {Amount = 1, Level = 70, Name = 'Sorcerer'}
                },
            },
        }--]]
    },

    FILL_ULT_BAR = true,


    --- PASSIVE, EASY, MEDIUM, HARD, EXTREME
    DIFFICULTY = 'EASY', 
    USE_BORROW = true, -- whether to replace agents with lvl 60 max
    BORROWED_AGENT_LEVEL = 60,
    CHARACTERS_INVINCIBLE = false,
    STUDIO_ENERGY_MULT = 0.5,
    STUDIO_HIT_ENERGY_MULT = 1,

    TEST_COMPANION = '8bdc68f8-cb56-4576-a193-689bb87043df',
    TEST_AGENTS = {
        'Kakashi',
        'Goku',
        'Miku',
    },

    --REPLACE_AFFLICTION = 'Fire',
    TEST_AGENT_ARTIFACTS = {
        Goku = {
            'FourLeafGrimoire',
            'FourLeafGrimoire',
            'FourLeafGrimoire',
            'FourLeafGrimoire',
            'DragonBall',
            'DragonBall',
        },
        Sasuke = {
            'Sharingan',
            'Sharingan',
            'Sharingan',
            'Sharingan',
            'FourLeafGrimoire',
            'FourLeafGrimoire',
        },
        Chihiro = {
            'CorpCapsule',
            'CorpCapsule',
            'CorpCapsule',
            'CorpCapsule',
            'DatensekiFragment',
            'DatensekiFragment',
        },
    },
})