-- Collection utils.
--
-- Author: qintianjie
-- Date:   2017-01-12

local modulename = 'collection_utils'
local _M = {}

_M._VERSION = '1.0.0'

_M.isTableEmpty = function (t)
	if t == nil or _G.next(t) == nil then
		return true
	else
		return false
	end
end


-- table contain key 
_M.containKey = function (tbl, key)
	for k,v in pairs(tbl) do
	  if k == key then return true; end
	end
	return false;
end

-- table contain key 
_M.containValue = function (tbl, value)
	for k,v in pairs(tbl) do
	  if v == value then return true; end
	end
	return false;
end

_M.array_in = function (arr, key)
	for i in pairs(arr) do
		 local k = arr[i]
		 if k == key then return true; end
	end
	return false
end

_M.table_size = function (table)
	if table == nil or type(table) ~= "table" or next(table) == nil then
		return 0
	else
		local count = 0
		for k, v in pairs(table) do
			count = count + 1
		end
		return count
	end
end

return _M