local Seed = #game.JobId < 1 and 0 or string.sub(string.gsub(game.JobId, '-', ''), 1, 1)
local NumberedSeed = tonumber(Seed, 16)
local Rng = Random.new(NumberedSeed)

return Rng :: Random