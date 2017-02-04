-- Author: qintianjie
-- Date:   2017-02-04

local modulename = "policy.unamein"
local _M = {}
_M._VERSION = '1.0.0'

local string_utils = require("utils.string_utils")

-- uidin
-- use the small server upstream for uid in [gray uids]
_M.process = function (params)
	local req_uname     = params["uname"]
	local gray_unames   = params["rule_data"]
	local ups_g1_size   = params["ups_g1_size"]
	local ups_g2_size   = params["ups_g2_size"]
	local ups_g1_name   = params["ups_g1_name"]
	local ups_g2_name   = params["ups_g2_name"]

	local ups  = ""
	if ups_g1_size < ups_g2_size then
		ups = ups_g2_name
	else
		ups = ups_g1_name
	end
	
	-- ngx.log(ngx.ERR, "-----------> " .. req_uname .. " : " .. gray_unames)
	if req_uname ~= nil and string.len(req_uname) > 0 and gray_unames ~= nil and string.len(gray_unames) > 0 then
		local gray_uname_array = string_utils.split(gray_unames, ",")
	    for i in pairs(gray_uname_array) do
	        gray_uname = gray_uname_array[i]
	        if gray_uname ~= nil and req_uname == gray_uname then
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