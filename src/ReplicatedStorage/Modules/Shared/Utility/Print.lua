
local PrintUtil = {}

function PrintUtil:vecF(p_Vector: vector | Vector3)
    return "Vec[" .. 
        math.round((p_Vector :: Vector3).X) .. ", " 
        .. math.round((p_Vector :: Vector3).Y) .. ", " 
        .. math.round((p_Vector :: Vector3).Z) ..  "]"
end

function PrintUtil:fV2(p_Vector: vector | Vector3)
    return "Vec[" .. 
        math.round((p_Vector :: Vector3).X) .. ", " 
        .. math.round((p_Vector :: Vector3).Y) .. "]"
end

return PrintUtil