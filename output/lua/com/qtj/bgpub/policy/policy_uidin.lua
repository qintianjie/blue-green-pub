-- 灰度策略  gray 
-- uid in [xxx, xxx, xxx]
--
-- Author: qintianjie
-- Date:   2017-02-04

local modulename = "policy.uidin"
local _M = {}
_M._VERSION = '1.0.0'

local string_utils = require("utils.string_utils")

-- uidin
-- use the small server upstream for uid in [gray uids]
_M.process = function (params)
	local req_uid     = params["uid"]
	local gray_uids   = params["rule_data"]
	local ups_g1_size = params["ups_g1_size"]
	local ups_g2_size = params["ups_g2_size"]
	local server_size =	params["server_size"]
	local ups_g1_name =	params["ups_g1_name"]
	local ups_g2_name =	params["ups_g2_name"]

	-- 首先走 server 多的 upstream
	local ups  = ""
	if ups_g1_size < ups_g2_size then
		ups = ups_g2_name
	else
		ups = ups_g1_name
	end
	
	-- 然后根据 uid 和 灰度数据决定是否走灰度 upstream, 即： server 少的 upstream
	if req_uid ~= nil and string.len(req_uid) > 0 and gray_uids ~= nil and string.len(gray_uids) > 0 then
		local gray_uid_array = string_utils.split(gray_uids, ",")
	    for i in pairs(gray_uid_array) do
	        gray_uid = tonumber(gray_uid_array[i])
	        if gray_uid ~= nil and gray_uid == req_uid then
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