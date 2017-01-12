-- Collection utils.
--
-- Author: qintianjie
-- Date:   2017-01-12

local modulename = 'collection_utils'
local _M = {}

_M._VERSION = '1.0.0'


-- table contain key 
_M.containKey = function (tbl, key)
	for k,v in pairs(tbl) do
	  if v == key then return true; end
	end
	return false;
end

return _M