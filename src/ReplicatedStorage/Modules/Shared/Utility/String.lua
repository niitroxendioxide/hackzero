local Util = {}

function Util:SplitTitleCaps(str: string): (string, number)
	str = str:gsub("(%u)", " %1")
	return str:gsub("^%s", "")
end

function Util:NormalizeSkillName(Name: string): string
    return string.lower((Name:gsub('%s+', '')))
end

function Util:LevenshteinDistance(A: string, B: string): number
    local LenA, LenB = #A, #B
    local Matrix = {}

    for i = 0, LenA do
        Matrix[i] = { [0] = i }
    end
    for j = 0, LenB do
        Matrix[0][j] = j
    end

    for i = 1, LenA do
        for j = 1, LenB do
            local Cost = (A:sub(i, i) == B:sub(j, j)) and 0 or 1
            Matrix[i][j] = math.min(
                Matrix[i - 1][j] + 1,        -- deletion
                Matrix[i][j - 1] + 1,        -- insertion
                Matrix[i - 1][j - 1] + Cost  -- substitution
            )
        end
    end

    return Matrix[LenA][LenB]
end

return Util