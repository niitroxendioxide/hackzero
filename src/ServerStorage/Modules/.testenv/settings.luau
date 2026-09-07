return table.freeze({
    REPLICATE_CONSTANTS = {
        HITBOXES = false,
        MARKERS = false,
        ENEMY_LOCATIONS = false,
    },

    MISSION = {
        --- Types: ChaosControl, Mission, Expedition
        TYPE = 'Mission',
        STAGE = {
            --- LeafVillage, Training, Testing, DailyImprovement, DungeonEx, HuecoMundo
            Stage = 'AlternativeDungeon',
            Act = 'Intro',
        },

        --- PASSIVE, EASY, MEDIUM, HARD, EXTREME. Studio overrides this with DIFFICULTY below.
        DIFFICULTY = 'EASY',

        --[[
            nil  -> defer to the stage act's `AutoGenerate` flag (DungeonEx/Intro sets it)
            true -> force a procedural run
            false-> force a static run even on an AutoGenerate act
        ]]
        PROCEDURAL = nil,

        --[[
            The run seed. Falls back to DATA.Mission_Seed, both unset = Generator creates random
        ]]
        SEED = 0,
        --[[
            `AutoGenerationData`. This is the block a lobby mission NPC would fill in.
        ]]
        GENERATION = {
            Rooms = 9, --- how many rooms to place (halls excluded)
            Extent = 25, --- hard cap on total tiles, rooms + halls
            Source = 'Rooms', --- folder of room models, relative to the stage's map asset
            Infinite = false, --- reserved, room streaming is not implemented yet
            Trail = 15, --- reserved, goes with Infinite
        },

        --[[
            Mission DATA. Three ways to fill this in:

            1. Pre-generated, out of the database (the existing flow, unchanged):
                   MissionId = 'LeafVillage_P01'

            2. Runtime-authored, no database entry. This is what the lobby NPC produces:
                   Kind = 'Recover'          -- resolves Components/Missions/Recover
                   Target_Item = 'Suitcase'  -- anything else the handler reads
               Together with PROCEDURAL/SEED/GENERATION above, that is a whole mission.
               Paste this block to try one:

                   TYPE  = 'Mission',
                   STAGE = { Stage = 'DungeonEx', Act = 'Intro' },
                   PROCEDURAL = true,
                   SEED = 0,
                   GENERATION = { Rooms = 8, Extent = 25 },
                   DATA = { Kind = 'Recover', Target_Item = 'Suitcase' },

            3. A complete mission written inline, when you already have the definition and
               only want the map generated:
                   Mission = { Triggers = {...}, Completion = {...} }
        ]]
        DATA = {
            --Mission_Seed = '12345-abcde-67890-fabcd',
            Kind = 'Recover',
            --MissionId = 'LeafVillage_P01',
            --Difficulty = 'EASY',
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
                    {Amount = 1, Level = 70, Name = 'SandShinobi'}
                },
            },]]
        }--]]
    },

    FILL_ULT_BAR = true,


    --- PASSIVE, EASY, MEDIUM, HARD, EXTREME
    DIFFICULTY = 'EASY', 
    USE_BORROW = true, -- whether to replace agents with lvl 60 max
    BORROWED_AGENT_LEVEL = 60,
    CHARACTERS_INVINCIBLE = false,
    STUDIO_ENERGY_MULT = 50,
    STUDIO_HIT_ENERGY_MULT = 1,

    TEST_COMPANION = '8bdc68f8-cb56-4576-a193-689bb87043df',
    TEST_AGENTS = {
        'Kakashi',
        'Naruto',
        'Goku',
    },

    --REPLACE_AFFLICTION = 'Fire',
    TEST_AGENT_ARTIFACTS = {
        Kakashi = {
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