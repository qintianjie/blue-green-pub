-- 灰度策略  gray, 改策略一般不建议用于线上.  uname 可以转换成数字，当 uid 看
-- uname in [xxx, xxx, xxx]
--
-- Author: qintianjie
-- Date:   2017-02-04

local modulename = "policy.unamein"
local _M = {}
_M._VERSION = '1.0.0'

local string_utils = require("utils.string_utils")

-- uname
-- use the small server upstream for uname in [gray unames]
_M.process = function (params)
	local req_uname     = params["uname"]
	local gray_unames   = params["rule_data"]
	local ups_g1_size   = params["ups_g1_size"]
	local ups_g2_size   = params["ups_g2_size"]
	local ups_g1_name   = params["ups_g1_name"]
	local ups_g2_name   = params["ups_g2_name"]

	local ups  = ""
	-- 首先走 server 多的 upstream
	if ups_g1_size < ups_g2_size then
		ups = ups_g2_name
	else
		ups = ups_g1_name
	end
	
	-- 然后根据 uid 和 灰度数据决定是否走灰度 upstream, 即： server 少的 upstream
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