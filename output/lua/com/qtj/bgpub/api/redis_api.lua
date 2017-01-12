-- Redis.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "dal.redis"
local _M = {}
_M._VERSION = '1.0.0'


local config_base 		 = require("configbase")
local redis_init_service = config_base.redisInitService


local redis_dal = require("dal.redis_dal")
local error_info     = require('utils.error_code').info

local setKeepalive = function(red) 
    local ok, err = red:keepalivedb()  
    if not ok then
        local info = errorInfo.REDIS_KEEPALIVE_ERROR
        ngx.log(ngx.ERR, '[BIZ_set_data] code: "'.. info[1] ..'"', err)
        return
    end
end

-- 连接线上 redis
_M.redisconn = function (self)
	local redis_conf 		 = config_base.redisConf
	-- 配置信息
	local red = redis_dal:new(redis_conf)
	-- 连接
	local ok, err = red:connectdb()

	if not ok then
		local info = error_info.REDIS_CONNECT_ERROR 
	    local desc = "Redis connect error [" .. cjson.encode(redisConf) .. "]" 
	    ngx.log(ngx.ERR, '[API] code: "', info[1], '". RedisConf: [' , cjson.encode(redisConf),  '] ', err)
	    -- return info[1], desc
	    return nil, info[1]
	else 
		-- local redis = red.redis
	    -- local sn_set_key = redis_init_service["initServiceName"]
	    -- local service_name_set, err = redis:smembers(sn_set_key)
	    -- local info = error_info.SUCCESS 

	    -- if red then setKeepalive(red) end
	    -- return error_info[1], service_name_set

	    -- if red then
	    -- 	red:keepalivedb() 
	    -- end
	    return red, "succeed"
	end
end 


return _M
