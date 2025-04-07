
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

return TableUtil