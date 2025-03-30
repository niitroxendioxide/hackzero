--
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local Shared = ReplicatedStorage.Modules.Shared
local Libs = ServerStorage.Modules.Libraries

--local Agents = require(Libs.Agents)
local Hitbox = require(Libs.Hitbox)
local Clock = require(Shared.Utility.Clock)

--
local Service = {}

function Service:Init()

	Clock:ThreadLoop(.35, function(_: number)
		local World = workspace:FindFirstChild('World') :: Folder

		for _, Zone in World.Map:FindFirstChild('Damage_Zones'):GetChildren() do
			local Size = Zone.Size
			local At = Zone.CFrame

			Hitbox:ForAgentsInZone(Size, At, function(Agent)
				Agent:TakeDamage(math.random(100, 250))
			end)
		end

	end)

end

return Service
