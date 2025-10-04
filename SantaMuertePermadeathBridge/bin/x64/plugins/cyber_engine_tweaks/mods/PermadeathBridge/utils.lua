---@param table table
---@param value any
---@return boolean
function Contains(table, value)
	for i=1, #table do
		if table[i] == value then
			return true
		end
	end

	return false
end

---@param table table
---@param name string
---@return boolean
function ContainsMatchingName(table, name)
	for i=1, #table do
		if (name:find("^" .. table[i]) ~= nil) then
			return true
		end
	end

	return false
end

---@param table1 table
---@param table2 table
---@return table
function ConcatTables(table1, table2)
	local result = {}

	for i=1, #table1 do
		table.insert(result, table1[i])
	end

	for i=1, #table2 do
		table.insert(result, table2[i])
	end

	return result
end

-- blatantly stolen from https://github.com/psiberx/cp2077-cet-kit/blob/main/GameSession.lua
---@return boolean
function IsPreGame()
	local success, isPreGame = pcall(function() return GetSingleton("inkMenuScenario"):GetSystemRequestsHandler():IsPreGame() end)

	return not success or isPreGame;
end