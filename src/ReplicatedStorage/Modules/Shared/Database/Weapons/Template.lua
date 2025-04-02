local Types = require("../../Types")
--
return {
    Name = "Template",
    Role_Needed = "Attack",
    Rarity = "Rare",

    Main_Stat = {
        StatName = "Attack%", -- To access % attacks, you must search with %%, double percent
        Base = 5,
        UpgradePerAscension = 5,
    },

    Sub_Stat = {
        StatName = "Affliction_Aptitude",
        Base = 10,
        UpgradePerAscension = 10,
    }

} :: Types.Weapon_Data