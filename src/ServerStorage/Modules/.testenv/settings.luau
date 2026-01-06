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
            Data = {
                MainFight = {
                    Enemies = {
                        [1] = {'Strongest', 1, 60},
                    },
                },
            },
        },
    },

    FILL_ULT_BAR = true,
    DIFFICULTY = 'EASY',
    USE_BORROW = false, -- whether to replace agents with your own ones
    BORROWED_AGENT_LEVEL = 60,

    TEST_AGENTS = {
        'Goku',
        'Jotaro3',
        'Tanjiro',
    },
})