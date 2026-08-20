local Names = {
    "Big",
    "Small",
    "Giant",
    "Crazy",
    "Overwhelming",
    "Insane",
    "Amazing",
    "Deadly",
    "Otherwordly",
    "Skibidi",
    "Menacing",
    "Lil",
    "Colossal", "Tiny", "Mighty", "Wacky", "Bouncy", "Wild", "Epic", "Savage", "Eerie", "Zany",
    "Chaotic", "Turbo", "Mega", "Mini", "Sneaky", "Brave", "Fearsome", "Ultra", "Shadow", "Shiny", "Rusty", "Hyper", "Ancient",
    "Fluffy", "Silent", "Loud", "Swift", "Mad", "Glorious", 
    "Bloody", "Cursed", "Royal", "Captain", "Honorable", "Mysterious", "Silly", "Noble", "Great", "Old", "Young", "Funky", "Grand", "Electric",
    "King", "Queen", "Burning"
}

local SecondNames = {
    "Artifact",
    "Destroyer",
    "Relic",
    "Item",
    "Seal",
    "Ruin",
    "Remnant",
    "Trace",
    "Museum Piece",
    "Memento",
    "Shadow",
    "Vestige",
    "Dreg",
    "Ghost",
    "Remain",
    "Product",
    "Thing",
    "Piece",
    "Ingredient"
}

return function(Seed: string)
    local First = (string.split(Seed, '-'))[1]
    local NmSeed = tonumber(First, 16)

    local Rng = Random.new(NmSeed)
    local Amount = Rng:NextInteger(3, 5)

    local Name = ""
    for i = 1, Amount do
        local Dir = Amount == i and SecondNames or Names

        Name = Name..(i~=1 and ' ' or '')..Dir[Rng:NextInteger(1, #Dir)]
    end

    return Name
end
