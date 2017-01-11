-- A test sample.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "api.bluegreen"
local _M = {}
_M._VERSION = '1.0.0'

local redis_api 	 = require("api.redis_api")
local error_code     = require('utils.error_code').info

local string_utils = require "utils.string_utils"


_M.ruleset = function ( self, conf )
	local service_keys = conf.s_key
	local ok, err = redis_api.redisconn()
	if not ok then
		local info = errorInfo.REDIS_CONNECT_ERROR 
	    local desc = "Redis connect error [" .. cjson.encode(redisConf) .. "]" 
	    ngx.log(ngx.ERR, '[BIZ] code: "', info[1], '". RedisConf: [' , cjson.encode(redisConf),  '] ', err)
    	return info[1], desc
	else
		local redis = red.redis 
	    local service_key_arr = string_utils.split(service_keys, ",")
	    local info = error_code.SUCCESS 
	    local data = {}
	    for i in pairs(service_key_arr) do
	        local s_key = service_key_arr[i]
	        if s_key ~= nil and string.len(s_key) > 0 then
	          local real_key = string_utils.trim(s_key)
	          local service_key = table.concat({prefixConf["policyPrefix"],real_key},":")

	          local switch = redis:hget(service_key, switch_key)
	          local optype = redis:hget(service_key, optype_key)
	          local opdata = redis:hget(service_key, opdata_key)
	          
	          bizgray_cache:set(service_key .. ":" .. switch_key, switch)
	          bizgray_cache:set(service_key .. ":" .. optype_key, optype)
	          bizgray_cache:set(service_key .. ":" .. opdata_key, opdata)
	      	  if switch== ngx.null or switch == "" or optype == ngx.null or optype == "" or opdata == ngx.null or opdata == "" then
	            ngx.log(ngx.ERR, "policy or policy item is null when set [" .. service_key .. "].")	  
	      	    info = errorInfo.POLICY_INVALID_ERROR
	      	  end
	       
	          data[switch_key] = switch
	          data[optype_key] = optype
	          data[opdata_key] = opdata
	        end
	    end
	    if red then setKeepalive(red) end
	    return info[1], data
	end
end


return _M