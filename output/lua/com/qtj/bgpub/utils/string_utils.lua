-- String utils.
--
-- Author: qintianjie
-- Date:   2016-10-28

local modulename = 'string_utils'
local _M = {}

_M._VERSION = '1.0.0'

_M.split = function (s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

_M.trim = function(str) 
	if str ~= nil then
		return string.gsub(str, "^%s*(.-)%s*$", "%1")
	else
		return ""
	end
end

_M.last_indexof = function(self, str, split)
	if str ~= nil and split ~= nil then
		local last_index = str:match('^.*()' .. split)
		if last_index ~= nil then
			return last_index
		end
	else 
		return -1
	end

	return -1;
end

return _M