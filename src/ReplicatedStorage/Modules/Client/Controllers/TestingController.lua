--!strict

--[[
    It's here to demonstrate how the Results work. 
    It is pointless and can be removed with no worries.
]]


local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Modules.Shared
local Res = require(Shared.Utility.Result)

local Controller = {}

function ReturnsResult(A: number, B: any): Res.Result<number, string>	
    if typeof(B) ~= 'number' then
        return Res.new(nil, "B is not a number! ")
    end
    
    return Res.new(A * B)
end

function Controller:Init()
    if true then
        return
    end

    local ListOfTries = {true, "Dog", 15, workspace.Baseplate} :: { any }

    for idx, ValueToTry in ListOfTries do
        local MyResult = ReturnsResult(5, ValueToTry)
        
        MyResult:Ok(function(Result: number): ()
            print("Success: ", Result)
        end)
        
        MyResult:Err(error)
    end
end

return Controller