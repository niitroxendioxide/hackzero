
export type ProbabilityDict = {
    [string]: {
        [string]: number,
    },

    GetRollTypeFrom: (self: ProbabilityDict, Key: 'Summon' | string) -> (string),
}

-- PROBABILITIES ARE DETERMINED WITH ENTRIES. NOT WITH PERCENT, 100 ENTRIES FOR ONE THING IS POSSIBLE, AND ADD 20 MORE ENTRIES
-- AND YOU'D HAVE THAT THE ONE WITH 100 ENTRIES IS AROUND 83.33% INSTEAD OF 100%
return {
    Summon = {
        ["Mythical"] = 0.5,
        ["Legendary"] = 7,
        ["Epic"] = 92.5,
    },

    -- TODO: Change the logic later :3
    GetRollTypeFrom = function(self: ProbabilityDict, Key: string)
        local Directory = self[Key]
        local Choices = {}

        for ItemName, Amount in Directory do
            for i = 1, math.round(Amount) do
                table.insert(Choices, ItemName)
            end
        end

        return Choices[math.random(1, #Choices)]
    end
} :: ProbabilityDict