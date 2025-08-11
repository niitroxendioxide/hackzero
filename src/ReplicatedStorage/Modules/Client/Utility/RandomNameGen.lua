

local Names = {
    "Big",
    "Small",
    "Giant",
    "Crazy",
    "Squishy",
    "Insane",
    "Amazing",
    "Deadly",
    "Otherwordly",
    "Thingy",
    "Mr.",
    "Ms.",
    "Skibidi",
    "Agar",
    "Don",
    "Sir",
    "Ma'am",
    "Menacing",
    "Lil",
    "Uzu",
    "Colossal", "Tiny", "Mighty", "Wacky", "Bouncy", "Wild", "Epic", "Savage", "Eerie", "Zany", "Dr.", "Prof.",
    "Chaotic", "Turbo", "Mega", "Mini", "Sneaky", "Brave", "Fearsome", "Ultra", "Shadow", "Shiny", "Rusty", "Hyper", "Ancient",
    "Crazy-Eyed", "Fluffy", "Silent", "Loud", "Swift", "Mad", "Glorious", "Stinky", "Bloody", "Cursed", "Royal", "Captain",
    "Commander", "Lord", "Lady", "Honorable", "Mysterious", "Silly", "Noble", "Great", "Old", "Young", "Funky", "Grand", "Electric",
    "King", "Queen",
}

local SecondNames = {
    "Thingy",
    "Doppler",
    "Master",
    "Plusha",
    "P-gent",
    "Agent P",
    "Jerry",
    "Insect",
    "Analyst",
    "Lake",
    "Rainbow",
    "Mike",
    "Ava",
    "Nugget",
    "Dino",
    "Shark",
    "Cell",
    "Inspector",
    "Teacher",
    "Katherine",
    "May",
    "Engine",
    "Reactor",
    "Candy",
    "Ice Cream",
    "Butters",
    "Hunter",
    "Baby",
    "Kee",
    "Shoe",
    "Blob", "Specter", "Wizard", "Raptor", "Penguin", "Lizard", "Crow", "Owl", "Bear", "Panther",
    "Fang", "Claw", "Bolt", "Storm", "Wave", "Fire", "Frost", "Leaf", "Root", "Moon", "Sun", "Star", "Comet", "Stone", "Rock", "Dust", "Echo", "Howler", "Screamer", "Baker", "Miner",
    "Tinker", "Smith", "Rider", "Walker", "Runner", "Seeker", "Keeper", "Watcher", "Maker", "Breaker", "Crusher", "Hopper", "Striker", "Slayer", "Jumper", "Fisher", "Diver", "Glider", "Spinner",
    "Tea", "Freddy",
}

return function(Seed: string)
    local First = (string.split(Seed, '-'))[1]
    local NmSeed = tonumber(First, 16)

    local Rng = Random.new(NmSeed)
    local Amount = 2--Rng:NextInteger(2)

    local Name = ""
    for i = 1, Amount do
        local Dir = Amount == i and SecondNames or Names

        Name = Name..(i~=1 and ' ' or '')..Dir[Rng:NextInteger(1, #Dir)]
    end

    return Name
end
