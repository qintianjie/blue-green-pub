-- Author: qintianjie
-- Date:   2017-02-04

local modulename = "policy.uidmod"
local _M = {}
_M._VERSION = '1.0.0'

local string_utils = require("utils.string_utils")

-- uidmod
-- use the small server upstream for uid mod [gray uids]
_M.process = function (params)
	local req_uid     = params["uid"]
	local str_mod_num   = params["rule_data"]
	local ups_g1_size = params["ups_g1_size"]
	local ups_g2_size = params["ups_g2_size"]
	local ups_g1_name =	params["ups_g1_name"]
	local ups_g2_name =	params["ups_g2_name"]

	local ups  = ""
	if ups_g1_size < ups_g2_size then
		ups = ups_g2_name
	else
		ups = ups_g1_name
	end

	if req_uid ~= nil and string.len(req_uid) > 0 and str_mod_num ~= nil and string.len(str_mod_num) > 0 then
		local mod_arr = string_utils.split(str_mod_num, ",")
		for i = 1, #mod_arr do  
    		local mod_item = mod_arr[i]
    		local mod_num = tonumber(mod_item)
		    if mod_num ~= nil and mod_num > 0 and req_uid % mod_num == 0 then
		      	if ups_g1_size < ups_g2_size then
	        		ups = ups_g1_name
	        	else
	        		ups = ups_g2_name
	        	end
	          	break
		    end
    	end		
	end

	return ups
end

return _M