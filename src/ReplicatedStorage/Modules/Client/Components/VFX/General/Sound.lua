---
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Client = ReplicatedStorage.Modules.Client

local Debugger = require(ReplicatedStorage.Modules.Shared.Utility.Debugger)
local AudioLib = require(Client.Libraries.Audio)
---
return function(
	At: CFrame | Vector3 | vector,
	Data: {
		FromDatabase: string,
		Id: string, 
		Volume: number?, 
		Priority: string?,
	}
): ()

	At = (typeof(At) == 'CFrame' and At.Position or At) :: Vector3;
	Data = Data or {}

	if (typeof(Data.Id) == 'number') then
		AudioLib:PlayId(Data.Id, {
			At = At,
			Volume = Data.Volume or 1,
			Category = 'Effects',
			Priority = Data.Priority,
		})
	elseif typeof(Data.FromDatabase) == 'string' then
		AudioLib:PlayFromDb(Data.FromDatabase, At);
	else
		Debugger:DebugLine("VFX.General.Hit", `Malformed audio cue: {Data}`, 3)
	end
end
