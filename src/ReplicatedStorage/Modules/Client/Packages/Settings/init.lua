return {
	Keybinds = require(script:WaitForChild('Keybinds')),
	Graphics = require(script:WaitForChild("Graphics")),
	Sound = require(script:WaitForChild("Sound")),
	QOL = require(script:WaitForChild("QOL")),


	-- For simple functionality, don't really need much
	-- depth for a separate module, this works


	--[[
		@param Data The entirety of the retrieved server data to set the settings to
	]]
	Set = function(self: {[any]: any}, Data: {})
		for k in Data do
			if not self[k] then
				continue
			end

			for newKey in Data[k] do
				-- new set in case there's missing data on settings
				self[k][newKey] = Data[k][newKey]
			end
		end
	end,

	--[[
		Retrieve a specific key from a settings category
		@param Key The settings key to access
		@param Category The category it belongs to

		@return any The value of the setting key given. Returns nil if invalid
	]]
	Get = function(self: {[any]: any}, Key: string, Category: string?): any?
		if not Category then
			for _, CategoryTable in self do
				if CategoryTable[Key] then
					return CategoryTable[Key];
				end
			end

			return nil;
		end
			
		return self[Category][Key];

	end,

	--[[
		Lists all categories for settings available;
		@return String list of all categories
	]]
	ListCategories = function(self: {[any]: any}): {string}
		local List = {}
		for k in self do
			if typeof(self[k]) == 'table' then
				table.insert(List, k)
			end
		end

		return List;
	end,

	--[[
		Lists all the options under this category
		@param Category The category to list options for
	]]
	ListOptions = function(self: {[any]: any}, Category: string): {string}
		local List = {};

		for Key in self[Category] do
			table.insert(List, Key);
		end

		return List :: {string};
	end,
}