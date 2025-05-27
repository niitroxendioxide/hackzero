
local TableUtil = {}

function TableUtil:printTable(t, tabcount: number?)
    tabcount = (tabcount or 0) :: number

    local tabCharacter = "  "
    local preText = string.rep(tabCharacter, tabcount :: number)

    for k, v in t do
        if typeof(v) == "table" then
            print(preText, `table "{k} ({typeof(k)})" \{`)
            TableUtil:printTable(v, (tabcount :: number)+1)
            print(preText, `\}`)
        else
            print(preText, k, v)
        end
    end
end

function TableUtil:GetDictLength(a: {any}, min: number?): number | boolean
    local k=0;
    for _ in a do
        if (min and k>min)then return true end
        k+=1;
    end
    return k;
end

function TableUtil:WriteKeys(dict: {any})
    local keys = {}
    for key in dict do
        table.insert(keys, key)
    end

    return keys;
end

function TableUtil:WriteValues(dict: {any})
    local vals = {}
    for _, val in dict do
        table.insert(vals, val)
    end

    return vals;
end

return TableUtil