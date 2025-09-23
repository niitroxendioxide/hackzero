return setmetatable({}, {
	__index = function(t, k)
		local value = setmetatable({}, {
			__call = function()
				return 0
			end,
			__eq = function(other)
				return false
			end,
			__add = function(self, other)
				return other
			end,
			__sub = function(self, other)
				return other
			end,
		});

		return value
	end
})