local Types = require("../../Types")
--
return {
    Name = "Turtle Way",
    Role_Needed = "Affliction",
    Tier = "Legendary",

    IconId = 86423073381951,
    ModelName = "",
    Passive_Description = "Idk made for goku",

    Main_Stat = {
        StatName = "Attack", -- To access % attacks, you must search with %%, double percent
        Base = 520,
        UpgradePerLevel = 4.25,
    },

    Advanced_Stat = {
        StatName = "Attack%",
        Base = 6,
        UpgradePerAscension = 4,
    }
} :: Types.Drive_Data