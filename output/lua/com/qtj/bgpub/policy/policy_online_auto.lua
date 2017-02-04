-- Author: qintianjie
-- Date:   2017-02-04

local modulename = "policy.online_auto"
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
	local ups_g1_name =	params["ups_g1_name"]
	local ups_g2_name =	params["ups_g2_name"]

	local ups  = ""
	if ups_g1_size == 0 then 
		ups = ups_g2_name
	elseif ups_g2_size == 0 then
		ups = ups_g1_name
	else
		local server_size = ups_g1_size + ups_g2_size
		local userid_num = tonumber(req_uid)
		if userid_num ~= nil and userid_num > 0 and userid_num % server_size < ups_g1_size then
			ups = ups_g1_name
		else
			ups = ups_g2_name
		end
	end

	return ups
end

return _M