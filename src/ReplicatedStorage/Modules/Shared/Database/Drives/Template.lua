local Types = require("../../Types")
--
return {
    Name = "Template",
    Role_Needed = "Attack",
    Tier = "Epic",

    IconId = 121441602694239,
    ModelName = "",
    Passive_Description = "",

    Main_Stat = {
        StatName = "Attack", -- To access % attacks, you must search with %%, double percent
        Base = 238,
        UpgradePerLevel = 4,
    },

    Advanced_Stat = {
        StatName = "Affliction_Aptitude",
        Base = 25,
        UpgradePerAscension = 30,
    }

} :: Types.Drive_Data