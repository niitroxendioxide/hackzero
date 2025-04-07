--
local RunService = game:GetService('RunService')

--
local ClockUtil = {
	__Saved = {}
}

function ClockUtil:ThreadLoop(Time: number, fn: (delta: number) -> ())
	local NewThread = task.spawn(function()
		while true do
			local Delta = task.wait(Time)

			fn(Delta)
		end
	end)

	table.insert(ClockUtil.__Saved, NewThread)

	return NewThread
end

function ClockUtil:Heartbeat(fn: (delta: number) -> ())
	local Connection = RunService.Heartbeat:Connect(fn)
	table.insert(ClockUtil.__Saved, Connection)

	return Connection
end

function ClockUtil:ClearAll()
	
	for _, SavedThread in ClockUtil.__Saved do
		if typeof(SavedThread) == 'thread' then
			task.cancel(SavedThread)
		else
			SavedThread:Disconnect()
		end
	end
	
	ClockUtil.__Saved = {}
end

return ClockUtil
