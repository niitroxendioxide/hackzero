
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

function TableUtil:GetDictLength(a: {[any]: any}, min: number?): number | boolean
    local k=0;
    for _ in a do
        if (min and k>min)then return true end
        k+=1;
    end
    return k;
end

function TableUtil:WriteKeys(dict: {any})
    local keys = {}
    dict = dict or {}
    for key in dict do
        table.insert(keys, key)
    end

    return keys;
end

function TableUtil:WriteValues(dict: {any})
    local vals = {}
    dict = dict or {}
    for _, val in dict do
        table.insert(vals, val)
    end

    return vals;
end

function TableUtil.PopRandom(p_tab: {any})
    local len = #p_tab
    if (len == 0) then return nil end

    local idx = math.random(1, len)
    local val = p_tab[idx]
    table.remove(p_tab, idx)

    return val
end

function TableUtil.GetRand(p_tab: {any})
    local len = #p_tab
    if (len == 0) then return nil end

    local idx = math.random(1, len)
    local val = p_tab[idx]

    return val
end

function TableUtil.CopyDeep<T, V>(p_Table: {[T]: V}): {[T]: V}
    local Copy = {}
    for Key, Val in p_Table do
        if typeof(Val) == "table" then
            Copy[Key] = TableUtil.CopyDeep(Val)
        else
            Copy[Key] = Val
        end
    end

    return Copy
end

return TableUtil