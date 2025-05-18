return {
    -- [[ DAMAGE TRAITS ]] --
    ["Ego"] = {
        Id = 1,
        Description = "Gain 2% attack speed for each ego stack, get stacks by perfectly dodging attacks, each stack lasts 5s",
    },

    ["Fury"] = {
        Id = 2,
        Description = "Gain a 5% attack damage boost for each enemy killed, each boost lasts 4s",
    },

    ["Rampage"] = {
        Id = 3,
        Description = "Damage increases for each % of health under 100%, max at 50%. Boost only applies to non-boss enemies"
    },

    -- [[ ELEMENTAL TRAITS ]] --
    ["Conductor"] = {
        Id = 4,
        Description = "Shock status applied to enemies spread to nearby enemies, dealing (1/EnemiesHit) times damage",
    },

    ["Crystallized"] = {
        Id = 5,
        Description = "Upon killing an enemy, cut nearby enemies and apply a slow-down effect"
    },

    ["Pyroclastic"] = {
        Id = 6,
        Description = "Applying burn on a frozen enemy will cause an explosion, doing AOE damage"
    },

    GetRandom = function(self)
        local Keys = {}
        for key in self do
            if typeof(self[key]) ~= 'table' then continue end
            table.insert(Keys, key)
        end

        return Keys[math.random(1, #Keys)]
    end,

    GetTraitById = function(self, id: number): string?
        for traitName, TraitData in self do
            if typeof(TraitData) ~= 'table' then continue end

            if TraitData.Id == id then
                return traitName
            end
        end

        return;
    end,
}