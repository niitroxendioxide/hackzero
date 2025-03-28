--
local RunService = game:GetService('RunService')

--
local ActiveCooldowns = {}
local Cooldown = {}

function Cooldown:Add(Name: string, Time: number)
	Time = Time or 1
	
	--
	if ActiveCooldowns[Name] then
		ActiveCooldowns[Name].Time = 0
		ActiveCooldowns[Name].Goal = Time
		
		return
	end
	
	ActiveCooldowns[Name] = {
		Goal = Time,
		Time = 0,
		Paused = false,
	}
	
	ActiveCooldowns[Name].Thread = RunService.Heartbeat:Connect(function(Delta: number)
		if not ActiveCooldowns[Name].Paused then
			ActiveCooldowns[Name].Time += Delta
		end
		
		if ActiveCooldowns[Name].Time >= ActiveCooldowns[Name].Goal then
			ActiveCooldowns[Name].Thread:Disconnect()
			ActiveCooldowns[Name] = nil
			
			return
		end
	end)
	
	return ActiveCooldowns[Name]
end

function Cooldown:IsOn(Name: string)
	return ActiveCooldowns[Name] ~= nil
end

function Cooldown:Remove()
	
end

return Cooldown
