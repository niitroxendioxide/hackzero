--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService("Players")

--
local Network = {
	__Cache = {},
}

function Network.new(Name: string, Type: 'Event' | 'Function' | 'Unreliable'): ()
	assert(RunService:IsServer(), 'Cannot create remotes on client')

	if script:GetAttribute(Name) ~= nil then
		warn('Remote'..Type, 'with name', Name, 'already exists')

		return
	end

	script:SetAttribute(Name, Type)

	local EventTypeObject = script:FindFirstChild(Type)
	if not EventTypeObject then
		EventTypeObject = Type == 'Unreliable' and Instance.new('UnreliableRemoteEvent') or Instance.new('Remote'..Type)
		EventTypeObject.Name = Type
		EventTypeObject.Parent = script
	end

	return EventTypeObject
end

function Network:GetPing()
	local Start = tick()
	local ServerTime = ReplicatedStorage.Ping:InvokeServer()
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
			until  RemoteExists ~= nil or  os.clock() - Clock > (MaximumWaitTime or 15)
			if RemoteExists == nil then return warn("Couldn\'t find remote", Name) end
		else
			return warn("Couldn\'t find remote", Name)
		end
	end

	return script:WaitForChild(RemoteExists, 15)
end

function Network:__GetBufferIdForName(Name: string): buffer
	local Order = table.find(Network:__GetSortedEventsArray(), Name)
	local bufferObject = buffer.create(1)
	buffer.writeu8(bufferObject, 0, Order)

	return bufferObject;
end

function Network:__GetNameForId(Buffer: buffer): string?
	local Number = buffer.readu8(Buffer, 0)
	local Events = Network:__GetSortedEventsArray()

	return Events[Number];
end

function Network:__GetSortedEventsArray()
	local TotalEvents = script:GetAttributes()
	local Names = {}
	for Key in TotalEvents do
		table.insert(Names, Key)
	end

	table.sort(Names, function(a: string, b: string): boolean
		return a > b;
	end)

	return Names
end

--[[
	Fire the specified remote event for a single client, or to the server if handled from client

	@param Name the name of the event to be fired
	@param ... The rest of the arguments to be passed to the client/server specified, includes the player in case of server
]]
function Network:Fire(Name: string, ...)
	local Event: RemoteEvent = Network:Get(Name)

	if not Event then
		Event = Network.new(Name, 'Event')
	end

	local bufferObject = Network:__GetBufferIdForName(Name)
	if RunService:IsClient() then
		Event:FireServer(bufferObject, ...)
	else
		local Args = {...};
		local Plr = table.remove(Args, 1);

		if not Plr:HasTag("Ping") then
			return
		end

		print(Args)

		Event:FireClient(Plr, bufferObject, table.unpack(Args))
	end
end

--[[
	Fire the specified remote event for all clients

	@param Name the name of the event to be fired
	@param ... The rest of the arguments to be passed to the clients
]]
function Network:FireForAll(Name: string, ...: any): ()
	if RunService:IsClient() then
		return warn('Cannot fireall in client')
	end

	local Event: RemoteEvent = Network:Get(Name)

	if not Event then
		Event = Network.new(Name, 'Event')
	end

	local OnePing = false;
	for _, Player in Players:GetPlayers() do
		if Player:HasTag("Ping") then OnePing = true end;
	end

	if not OnePing then return end;

	local bufferObject = Network:__GetBufferIdForName(Name)
	Event:FireAllClients(bufferObject, ...)

	return;
end

--[[
	Fire the specified remote event for all clients

	@param Blacklisted : `Player` the player for which the event will not be fired for
	@param Name : `string` the name of the event to be fired
	@param ... the rest of the arguments to be passed to the clients
]]
function Network:FireForAllBut(Blacklisted: Player, Name: string, ...)
	if RunService:IsClient() then
		return warn('Cannot fireall in client')
	end

	local Event: RemoteEvent = Network:Get(Name)

	if not Event then
		Event = Network.new(Name, 'Event')
	end

	local bufferObject = Network:__GetBufferIdForName(Name)
	for _, Player in Players:GetPlayers() do
		if Player == Blacklisted or not Player:HasTag("Ping") then
			continue
		end

		Event:FireClient(Player, bufferObject, ...)
	end

	return;
end

if RunService:IsServer() then
	function Network:On<T...>(Name: string, fn: (Player: Player, T...) -> ())
		local Event = Network:Get(Name) :: RemoteEvent
		if not Event then
			return
		end

		if Network.__Cache[Name] == nil then
			Network.__Cache[Name] = {}
		end

		local Connection = Event.OnServerEvent:Connect(function(Player: Player, Buffer: buffer, ...)
			local EventName = Network:__GetNameForId(Buffer)

			if EventName == Name then
				fn(Player, ...)
			end
		end)

		table.insert(Network.__Cache[Name], Connection)
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
	function Network:On<T...>(Name: string, fn: any)
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

return Network
