return {
    Level = 1,
    Experience = 0,

    Money = 1000,
    Gems = 0,

    Stats = {
        TotalDamage = 0,
        TotalDaze = 0,
        TotalKills = 0,
        TotalPulls = 0,
        TotalMissions = 0,
        TotalGemsSpent = 0,
        TotalMoneySpent = 0,
    },

    Settings = {
        Graphics = {
            CameraShake = true,
            VisualEffects = true,
            AuraEffects = true,
            ScreenTextEffects = true,
            DisableDamageIndicators = false,
            DisableLightningEffects = false,
            ImpactFrames = false,
        },
        Sound = {
            Master_Volume = 50,
            Music_Volume = 50,
            Effects_Volume = 50,
            Voices_Volume = 50,
            Emotes_Volume = 50,
            Interface_Volume = 50,

            Sound_Effects = true,
        },
        QOL = {
            MultipleIndicators = false,
        },
        Keybinds = {
            
        },
    },

    StagesUnlocked = {
        Earth = {
            Intro = true,
        },

        Training = {
            Intro = true,
        }
    },

    Quests = {
        Daily = {
            --[[ 
                Index is by number, ex.  
                [1] = {
                    Id: string,
                    Name: string,
                    Progress: {},
                    Rewards: {},
                },
            --]]
        },
        Main = {},
        Interactions = {},
    },
    Missions = {
        Completed = {},
    },
    Companions = {},
    Agents = {},
    Achievements = {},
    Titles = {},
    Items = {
        Weapons = {},
        Artifacts = {},
        Progress = {},
        Event = {},
        Drives = {},
        Skins = {},
        Tokens = {},
    },
    Warnings = {},
    ChaosControl = {
        DailyImprovement = {},
        ApocalypseTower = {},
        AgentExperience = {},
    },
}