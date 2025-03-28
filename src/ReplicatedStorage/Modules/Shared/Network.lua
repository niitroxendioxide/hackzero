--
local RunService = game:GetService('RunService')

--
local Network = {
	__Cache = {}, 
}

function Network.new(Name: string, Type: 'Event' | 'Function' | 'Unreliable')
	assert(RunService:IsServer(), 'Cannot create remotes on client')
	
	if script:GetAttribute(Name) ~= nil then
		warn('Remote'..Type, 'with name', Name, 'already exists')
		
		return
	end
	
	script:SetAttribute(Name, Type)

	local EventTypeObject = script:FindFirstChildOfClass(Type)
	if not EventTypeObject then
		EventTypeObject = Type == 'Unreliable' and Instance.new('UnreliableRemoteEvent') or Instance.new('Remote'..Type)
		EventTypeObject.Name = Type
		EventTypeObject.Parent = script
	end

	return EventTypeObject
end

function Network:Fire(Name: string, ...)
	local Event: RemoteEvent = Network:Get(Name)
	
	if not Event then
		Event = Network.new(Name, 'Event')
	end
	
	local bufferObject = Network:__GetBufferIdForName(Name)
	if RunService:IsClient() then
		Event:FireServer(bufferObject, ...)
	else
		local Args = {...}	
		local Plr = table.remove(Args, 1)		
		
		Event:FireClient(Plr, bufferObject, table.unpack(Args))
	end
end

function Network:FireForAll(Name: string, ...)
	if RunService:IsClient() then
		return warn('Cannot fireall in client')
	end
	
	local Event: RemoteEvent = Network:Get(Name)

	if not Event then
		Event = Network.new(Name, 'Event')
	end

	local bufferObject = Network:__GetBufferIdForName(Name)
	Event:FireAllClients(bufferObject, ...)
end

function Network:FireForAllBut(Blacklisted: Player, Name: string, ...)
	if RunService:IsClient() then
		return warn('Cannot fireall in client')
	end

	local Event: RemoteEvent = Network:Get(Name)

	if not Event then
		Event = Network.new(Name, 'Event')
	end

	local bufferObject = Network:__GetBufferIdForName(Name)
	for _, Player in game.Players:GetPlayers() do
		if Player == Blacklisted then
			continue
		end
		
		Event:FireClient(Player, bufferObject, ...)
	end
end

if RunService:IsServer() then
	
	function Network:On(Name: string, fn: (Player: Player, any) -> ())
		local Event = Network:Get(Name) :: RemoteEvent
		if not Event then
			return
		end

		if Network.__Cache[Name] == nil then
			Network.__Cache[Name] = {}
		end

		table.insert(Network.__Cache[Name], Event.OnServerEvent:Connect(function(Player: Player, Buffer: buffer, ...)
			local EventName = Network:__GetNameForId(Buffer)

			if EventName == Name then
				fn(Player, ...)
			end
		end))
	end
	
	function Network:Handle(Name: string, fn: (Player: Player, any) -> ())
		local Event = Network:Get(Name) :: RemoteFunction
		if not Event then
			return
		end

		if Network.__Cache[Name] == nil then
			Network.__Cache[Name] = {}
		end

		Event.OnServerInvoke = function(Player: Player, Buffer: buffer, ...)
			local EventName = Network:__GetNameForId(Buffer)

			if EventName == Name then
				fn(Player, ...)
			end
		end
	end
	
elseif RunService:IsClient() then
	function Network:On(Name: string, fn: (any) -> ())
		local Event = Network:Get(Name) :: RemoteEvent
		if not Event then
			return
		end

		if Network.__Cache[Name] == nil then
			Network.__Cache[Name] = {}
		end

		table.insert(Network.__Cache[Name], Event.OnClientEvent:Connect(function(Buffer: buffer, ...)
			local EventName = Network:__GetNameForId(Buffer)

			if EventName == Name then
				fn(...)
			end
		end))
	end
end

function Network:GetPing()
	local Start = tick()
	local ServerTime = game:GetService('ReplicatedStorage').Ping:InvokeServer()
	return ServerTime - Start, tick() - ServerTime
end

function Network:Get(Name: string, MaximumWaitTime: number?)
	local RemoteExists = script:GetAttribute(Name)

	if RemoteExists == nil then
		if RunService:IsClient() then
			local Clock = os.clock()
			
			repeat
				RemoteExists = script:GetAttribute(Name)
				task.wait()
			until  RemoteExists ~= nil or  os.clock() - Clock > (MaximumWaitTime or 5)
			if RemoteExists == nil then return end
		else
			return
		end
	end

	return script:WaitForChild(RemoteExists, 15)
end

function Network:__GetBufferIdForName(Name: string): buffer
	local Order = table.find(Network:__GetSortedEventsArray(), Name)
	local bufferObject = buffer.create(1)
	buffer.writeu8(bufferObject, 0, Order)
	
	return bufferObject
end

function Network:__GetNameForId(Buffer: buffer): string?
	local Number = buffer.readu8(Buffer, 0)
	local Events = Network:__GetSortedEventsArray()
	
	return Events[Number]	
end

function Network:__GetSortedEventsArray()
	local TotalEvents = script:GetAttributes()
	local Names = {}
	for Key in TotalEvents do
		table.insert(Names, Key)
	end

	table.sort(Names, function(a, b) return a > b end)
	
	return Names
end

return Network
