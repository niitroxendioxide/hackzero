return {
    Name = "Ice Template",
    Tier = "Epic",

    Passive = {
        Description = "Freeze passive idk",
    },

    PrimaryAttack = {
        Description = "Ice attack 1",
    },

    SecondaryAttack = {
        Description = "ICe attack 2",
    },

    Stats = { 
        Defense = NumberRange.new(14, 32),
        Attack = NumberRange.new(220, 480),
        AttackSpeed = NumberRange.new(0.86, 1.26),
        AttackRate = NumberRange.new(4, 7.6),
        Speed = 24,
    },

    LevelStats = {
        Defense = NumberRange.new(0.11, 0.31),
        Attack = NumberRange.new(5.5, 25),
        Speed = 0.03,
    },
}