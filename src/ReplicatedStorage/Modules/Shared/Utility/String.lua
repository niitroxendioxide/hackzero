local Util = {}

function Util:SplitTitleCaps(str: string): (string, number)
	str = str:gsub("(%u)", " %1")
	return str:gsub("^%s", "")
end

return Util