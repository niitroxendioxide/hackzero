return {
    Name = "Companion Template",
    Tier = "Epic",

    Passive = {
        Description = "Does something",
    },

    Attack = {
        Description = "Does something",
    },

    Stats = { 
        Defense = NumberRange.new(12, 30),
        Attack = NumberRange.new(200, 450),
        AttackSpeed = NumberRange.new(0.85, 1.25),
        AttackRate = NumberRange.new(4, 7.5),
        Speed = 24,
    },

    LevelStats = {
        Defense = NumberRange.new(0.1, 0.3),
        Attack = NumberRange.new(5, 24),
        Speed = 0.025,
    },
}