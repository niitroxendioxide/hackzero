
export type ProbabilityDict = {
    [string]: {
        [string]: number,
    },

    GetRollTypeFrom: (self: ProbabilityDict, Key: string) -> (string),
}

-- PROBABILITIES ARE DETERMINED WITH ENTRIES. NOT WITH PERCENT, 100 ENTRIES FOR ONE THING IS POSSIBLE, AND ADD 20 MORE ENTRIES
-- AND YOU'D HAVE THAT THE ONE WITH 100 ENTRIES IS AROUND 83.33% INSTEAD OF 100%
return {
    Summon = {
        ["Mythical"] = 0.5,
        ["Legendary"] = 7,
        ["Rare"] = 92.5,
    },

    Test = {
        a = 12,
        b = 19,
        c = 32,
        d = 55,
        g = 56,
        f = 91,
    },


    GetRollTypeFrom = function(self: ProbabilityDict, Key: string)
        local Directory = self[Key]
        local Choices = {}
        for ItemName, Amount in Directory do
            for i = 1, Amount do
                table.insert(Choices, ItemName)
            end
        end

        return Choices[math.random(1, #Choices)]
    end
} :: ProbabilityDict