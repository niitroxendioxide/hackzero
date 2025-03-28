-- Camera Shake Presets
-- Stephen Leitnick
-- February 26, 2018

--[[
	
	CameraShakePresets.Bump
	CameraShakePresets.Explosion
	CameraShakePresets.Earthquake
	CameraShakePresets.BadTrip
	CameraShakePresets.HandheldCamera
	CameraShakePresets.Vibration
	CameraShakePresets.RoughDriving
	
--]]



local CameraShakeInstance = require(script.Parent.CameraShakeInstance)

local CameraShakePresets = {


	-- A high-magnitude, short, yet smooth shake.
	-- Should happen once.
	Bump = function()
		local c = CameraShakeInstance.new(2.5, 4, 0.1, 0.75)
		c.PositionInfluence = Vector3.new(0.15, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end;


	-- An intense and rough shake.
	-- Should happen once.
	Explosion = function()
		local c = CameraShakeInstance.new(5, 10, 0, 1.5)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(4, 1, 1)
		return c
	end;

	-- An intense and rough shake.
	-- Should happen once.
	BlowUp = function()
		local c = CameraShakeInstance.new(5, 10, .05, 0.75)
		c.PositionInfluence = Vector3.new(0.1, 0.1, 0.1)
		c.RotationInfluence = Vector3.new(1, 0.5, 0.85)
		return c
	end;

	-- A low magnitude and rough shake.
	-- Should happen once.
	Hit = function()
		local c = CameraShakeInstance.new(2.5, 6, .05, 0.5)
		c.PositionInfluence = Vector3.new(0.07, 0.07, 0.07)
		c.RotationInfluence = Vector3.new(0.45, 0.25, 0.65)
		return c
	end;


	-- A low magnitude and rough shake.
	-- Should happen once.
	BarrageHit = function()
		local c = CameraShakeInstance.new(2.5, 4, .05, 0.5)
		c.PositionInfluence = Vector3.new(0.05, 0.05, 0.05)
		c.RotationInfluence = Vector3.new(0.35, 0.15, 0.45)
		return c
	end;


	-- An intense and rough shake.
	-- Should happen once.
	HeavilyHurt = function()
		local c = CameraShakeInstance.new(3, 8, 0.05, 0.85)
		c.PositionInfluence = Vector3.new(0.18, 0.15, 0.15)
		c.RotationInfluence = Vector3.new(0.86, 0.56, 0.63)
		return c
	end;


	-- Powerful camerashake
	-- Should happen once.
	WindBreak = function()
		local c = CameraShakeInstance.new(3, 5, 0.05, 0.75)
		c.PositionInfluence = Vector3.new(0.08, 0.08, 0.08)
		c.RotationInfluence = Vector3.new(0.45, 0.3, 0.35)
		return c
	end;


	Surprise = function()
		local c = CameraShakeInstance.new(2, 3, 0.05, 0.45)
		c.PositionInfluence = Vector3.new(0.08, 0.08, 0.08)
		c.RotationInfluence = Vector3.new(0.15, 0.125, 0.26)
		return c
	end;


	-- An intense and rough shake.
	-- Should happen once.
	Shoot = function()
		local c = CameraShakeInstance.new(2, 6, 0.05, 0.65)
		c.PositionInfluence = Vector3.new(0.05, 0.05, 0.125)
		c.RotationInfluence = Vector3.new(0.6, 0.6, 0.6)
		return c
	end;

	-- A continuous, rough shake
	-- Sustained.
	Earthquake = function()
		local c = CameraShakeInstance.new(0.6, 3.5, 2, 10)
		c.PositionInfluence = Vector3.new(0.25, 0.25, 0.25)
		c.RotationInfluence = Vector3.new(1, 1, 4)
		return c
	end;

	-- A continuous, rough shake
	-- Sustained.
	Terrified = function()
		local c = CameraShakeInstance.new(0.9, 4.5, 0.25, 6)
		c.PositionInfluence = Vector3.new(0.33, 0.33, 0.33)
		c.RotationInfluence = Vector3.new(2, 2, 4)
		return c
	end;


	-- A bizarre shake with a very high magnitude and low roughness.
	-- Sustained.
	BadTrip = function()
		local c = CameraShakeInstance.new(10, 0.15, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0.15)
		c.RotationInfluence = Vector3.new(2, 1, 4)
		return c
	end;


	-- A subtle, slow shake.
	-- Sustained.
	HandheldCamera = function()
		local c = CameraShakeInstance.new(1, 0.25, 5, 10)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 0.5, 0.5)
		return c
	end;


	-- A very rough, yet low magnitude shake.
	-- Sustained.
	Vibration = function()
		local c = CameraShakeInstance.new(0.8, 5, 0.1, 0.5)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(1.25, 0, 4)
		return c
	end;

	-- A very rough, yet low magnitude shake.
	-- Sustained.
	Barrage = function()
		local c = CameraShakeInstance.new(0.6, 5, 0.05, 0.65)
		c.PositionInfluence = Vector3.new(0, 0.15, 0)
		c.RotationInfluence = Vector3.new(0.5, 0.1, 0.5)
		return c
	end;


	-- A slightly rough, medium magnitude shake.
	-- Sustained.
	RoughDriving = function()
		local c = CameraShakeInstance.new(1, 2, 1, 1)
		c.PositionInfluence = Vector3.new(0, 0, 0)
		c.RotationInfluence = Vector3.new(1, 1, 1)
		return c
	end;


}


return setmetatable({}, {
	__index = function(t, i)
		local f = CameraShakePresets[i]
		if (type(f) == "function") then
			return f()
		end
		error("No preset found with index \"" .. i .. "\"")
	end;
})