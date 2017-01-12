-- 蓝绿发布 API 接口层.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "api.bluegreen"
local _M = {}
_M._VERSION = '1.0.0'

local redis_api 	 = require("api.redis_api")
local error_code     = require('utils.error_code').info

-- 配置信息
local config_base 	 = require("configbase")
local switch_key    = config_base.fields["switch"]
local optype_key    = config_base.fields["optype"]
local opdata_key    = config_base.fields["opdata"]

local string_utils = require "utils.string_utils"

-- 规则缓存在 nginx dict 名
local rule_data_cache = ngx.shared["dict_rule_data"]


-- 根据传入的 service_name ，从 redis 取相关规则数据，设置到 shared dict 中
-- conf = {["s_key":xxx]} : s_key ==> 传入的服务名，可以逗号分隔为多个
-- 
_M.ruleset = function ( self, conf )
	local service_keys = conf.s_key
	local red, err = redis_api.redisconn()
	if not red then
		local info = error_code.REDIS_CONNECT_ERROR 
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
	          -- 构造 redis key:   policyPrefix:servicename 格式
	          local service_key = table.concat({config_base.prefixConf["policyPrefix"],real_key},":")

	          -- 每个 key 都是一个 map， 对应规则数据有:  switch 路由, optype 操作类型, opdata: 操作数据
	          local switch = redis:hget(service_key, switch_key)
	          local optype = redis:hget(service_key, optype_key)
	          local opdata = redis:hget(service_key, opdata_key)

	          data[s_key .. "." .. switch_key] = switch
	          data[s_key .. "." .. optype_key] = optype
	          data[s_key .. "." .. opdata_key] = opdata

	          -- 验证数据有效性， 这里不直接 return 是考虑更新多个服务的时，前面服务的数据不全，不影响后面服务继续面服务的数据不全，不影响后面服务继续
	      	  if switch== ngx.null or switch == "" or optype == ngx.null or optype == "" or opdata == ngx.null or opdata == "" then
	      	  	info = error_code.POLICY_INVALID_ERROR
	      	  	ngx.log(ngx.ERR, string.format("[API] [%d] %s[%s]", info[1], info[2], service_key))	
	            -- ngx.log(ngx.ERR, "policy or policy item is null when set [" .. service_key .. "].")	  
	      	    
	      	    data[s_key .. ".result"] = "data_error"
	      	  else
	      	  	-- 将 redis 得到的数据，存入 ngx.shared.dict 中
	          	rule_data_cache:set(service_key .. ":" .. switch_key, switch)
	          	rule_data_cache:set(service_key .. ":" .. optype_key, optype)
	          	rule_data_cache:set(service_key .. ":" .. opdata_key, opdata)
	          	data[s_key .. ".result"] = "succeed"
	      	  end
	        end
	    end
	    -- will close current redis connect
	    if red then redis_api.setKeepalive(red) end
	    return info[1], data
	end

	return nil, ""
end


return _M