-- 蓝绿发布 BIZ 层.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "biz.bluegreen"
local _M = {}
_M._VERSION = '1.0.0'

local redis_biz 	 = require("biz.redis_biz")
local error_code     = require('utils.error_code').info

local upstream 		   = require ("ngx.upstream")
local string_utils     = require ("utils.string_utils")

-- 配置信息
local config_base 	= require("configbase")
local switch_key    = config_base.fields["switch"]
local optype_key    = config_base.fields["optype"]
local opdata_key    = config_base.fields["opdata"]
local ups_group     = config_base.ups_group

local string_utils     = require "utils.string_utils"
local collection_utils = require "utils.collection_utils"

-- 规则缓存在 nginx dict 名
local rule_data_cache = ngx.shared["dict_rule_data"]

-- 根据传入的 service_name ，从 redis 取相关规则数据，设置到 shared dict 中
-- conf = {["s_key":xxx]} : s_key ==> 传入的服务名，可以逗号分隔为多个
_M.ruleset = function (conf)
	local service_keys = conf.s_key
	local red, err = redis_biz.redisconn()
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

	    -- if red then
	    -- 	local temp_t = {["k1"]="v1", ["grayType"]="unamein"}
	    -- 	local redis = red.redis 
	    -- 	-- red:hmset("bizgray:gray:apollo", "temp", temp)
	    -- 	-- local res, err = redis:hmset("biztech:gray:apollo", "switch", nil, "grayType", "uidmod")
	    -- 	-- HMSET biztech:gray:apollo graySwitch true grayType in grayData 111,222,333

	    -- 	local res, err = redis:hmset("biztech:gray:apollo", "abc", cjson.encode(temp_t))
	    -- 	local bb, err = redis:hget("biztech:gray:apollo", "abc")
	    -- 	local t_001 = cjson.decode(bb)
	    -- 	t_001["k1"] = "abcdkkkk"
	    -- 	redis:hmset("biztech:gray:apollo", "abc", cjson.encode(t_001))

	    -- 	redis:hdel("biztech:gray:apollo", "switch")
	    -- 	ngx.say("====> bb: " .. t_001["k1"])
	    -- end

	    -- will close current redis connect
	    if red then redis_biz.setKeepalive(red) end
	    return info[1], data
	end

	return nil, ""
end

-- get ruledata from ngx.shared.dict
_M.ruleget = function (conf)
	local service_name = conf.s_key
	local rule_data_cache = ngx.shared["dict_rule_data"]
	local result = {}

	if service_name and string.len(service_name) > 0 then
        local key_prefix   = config_base.prefixConf["policyPrefix"]

        local buffer_switch_key = table.concat({key_prefix, service_name, switch_key}, ":")
        local buffer_optype_key = table.concat({key_prefix, service_name, optype_key}, ":")
        local buffer_opdata_key = table.concat({key_prefix, service_name, opdata_key}, ":")

        
        result["service_name"] = service_name
        result["cache.prifix"] = key_prefix .. ":" .. service_name

        local data = {}
        data[switch_key] = rule_data_cache:get(buffer_switch_key)
        data[optype_key] = rule_data_cache:get(buffer_optype_key)
        data[opdata_key] = rule_data_cache:get(buffer_opdata_key)

        result["data"] = data
	else
		result["service_name"] = "ALL"
        result["cache.prifix"] = "ALL limit 1000"

        local switch_keys = rule_data_cache:get_keys(100)  
        local data = {} 
        for k, v in ipairs(switch_keys) do       
            data[v] = rule_data_cache:get(v)
        end

        result["data"] = data
	end

	return result
end

-- delete ruledata from ngx.shared.dict
-- NOTE: make sure delete data from redis by manual
_M.ruledelete = function (conf)
	local service_keys = conf.s_key
	local service_key_arr = string_utils.split(service_keys, ",")
	for i in pairs(service_key_arr) do
        local s_key = service_key_arr[i]
        if s_key ~= nil and string.len(s_key) > 0 then
          	local real_key = string_utils.trim(s_key)
          	-- 构造 redis key:   policyPrefix:servicename 格式
          	local service_key = table.concat({config_base.prefixConf["policyPrefix"],real_key},":")

			rule_data_cache:set(service_key .. ":" .. switch_key, nil)
			rule_data_cache:set(service_key .. ":" .. optype_key, nil)
			rule_data_cache:set(service_key .. ":" .. opdata_key, nil)
		end
	end
	return "ok", "succeed deleted"
end

-- update switch ruledata from ngx.shared.dict
-- NOTE: make sure delete data from redis by manual
_M.switchupdate = function (conf)
	local switch_value = conf.switch_value
	local service_keys = conf.s_key
	local service_key_arr = string_utils.split(service_keys, ",")
	for i in pairs(service_key_arr) do
        local s_key = service_key_arr[i]
        if s_key ~= nil and string.len(s_key) > 0 then
          	local real_key = string_utils.trim(s_key)
          	-- 构造 redis key:   policyPrefix:servicename 格式
          	local service_key = table.concat({config_base.prefixConf["policyPrefix"],real_key},":")
			rule_data_cache:set(service_key .. ":" .. switch_key, switch_value)
		end
	end
	return "0", "succeed update switch value"
end


-- get upstream's server by service_name & group_name
_M.upstream_get = function (self, conf) 
	local ups = upstream.get_upstreams()
    local get_servers = upstream.get_servers

    local servicename = conf.s_key
    local groupname = conf.g_key

    local ups_list = {}
    for _, u in ipairs(ups) do
    	repeat 
    		local server_item = {}
			-- ngx.say("-----------> ups: " .. u )
			local last_index = string_utils:last_indexof(u, "_")
	    	if servicename ~= nil and string.len(servicename) > 0 and  u~= nil and string.len(u) > 0 then
	    		if last_index == nil or last_index < 1 then
	    			break;
	    		end

	    		local ups_prefix = string.sub(u, 1, last_index - 1)
	    		if ups_prefix ~= servicename then
	    			break;
	    		end
	    	end

	    	if groupname ~= nil and string.len(groupname) > 0 and u ~= nil and string.len(u) > 0 then
	    		if last_index == nil or last_index < 1 then
	    			break;
	    		end

	    		local ups_sufix = string.sub(u, last_index + 1, -1)
	    		if ups_sufix ~= groupname then
	    			break;
	    		end
	    	end


	        local srvs, err = get_servers(u)

	        if not srvs then
	            ngx.log(ngx.ERR, string.format("no server for upstream %s", u))
	        else 
	        	for _, srv in ipairs(srvs) do
		 	        local first = true
		 	        local key_item = {}
		 	        local ip_port = ""
	                for k, v in pairs(srv) do
	                	key_item[k] = v

	                    if first then
	                    	ip_port = v
	                        first = false
	                    end
	                end

	                server_item[ip_port] = key_item
	        	end
	        end
	        ups_list[u] = server_item
    	until true
    end
    return ups_list
end

-- _M.upstream_save_to_redis = function (self, conf)
-- 	local s_key = conf.s_key
-- 	local g_key = conf.g_key
-- 	local value = conf.value
-- 	local red, err = redis_biz.redisconn()
-- 	if not red then
-- 		local info = error_code.REDIS_CONNECT_ERROR 
-- 	    local desc = "Redis connect error [" .. cjson.encode(redisConf) .. "]" 
-- 	    ngx.log(ngx.ERR, '[BIZ] code: "', info[1], '". RedisConf: [' , cjson.encode(redisConf),  '] ', err)
--     	return -1;
-- 	else
-- 		local redis = red.redis 
-- 		local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_key},":")
-- 		local ok, err = redis:hmset(service_key, g_key, cjson.encode(value))
-- 		if err ~= nil then
-- 			ngx.log(ngx.ERR, string.format("Error when save ups[%s] to redis. err: %s", s_key, cjson.encode(err)))
-- 			return -1;
-- 		else 
-- 			return 0;
-- 		end 
-- 	end
-- 	return -1;
-- end

_M.upstream_save_to_redis = function (self, conf)
	local s_key = conf.s_key
	local g_key = conf.g_key
	local value = conf.value
	local red, err = redis_biz.redisconn()
	if not red then
		local info = error_code.REDIS_CONNECT_ERROR 
	    local desc = "Redis connect error [" .. cjson.encode(redisConf) .. "]" 
	    ngx.log(ngx.ERR, '[BIZ] code: "', info[1], '". RedisConf: [' , cjson.encode(redisConf),  '] ', err)
    	return -1;
	else
		local redis = red.redis 

		if s_key ~= nil and string.len(s_key) > 0 and g_key ~= nil and string.len(g_key) > 0 then
			local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_key},":")
			local hash_key    = "_" .. g_key
			local hash_value  = value[service_key .. hash_key]

			local ok, err = redis:hmset(service_key, hash_key, cjson.encode(value))
			if err ~= nil then
				ngx.log(ngx.ERR, string.format("Error when save ups[%s] to redis. err: %s", hash_key, cjson.encode(err)))
				return -1;
			else 
				return 0;
			end
		end

		if s_key ~= nil and string.len(s_key) > 0 and (g_key == nil or string.len(g_key) == 0) then
			local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_key},":")

			for i in pairs(ups_group) do
		        local group = ups_group[i]
		        local hash_key    = "_" .. group

		        local value_key = s_key .. hash_key

		        if value ~= nil then
		        	for k, v in pairs(value) do
		        		if string.lower(value_key) == string.lower(k) then
		        			local ok, err = redis:hmset(service_key, hash_key, cjson.encode(v))
		        			if err ~= nil then
		        				ngx.log(ngx.ERR, string.format("Error when save ups[%s] to redis. err: %s", hash_key, cjson.encode(err)))
		        			end
		        		end
		        	end
		        end
		    end

			return 2
		end

		if (s_key == nil or string.len(s_key) == 0) and g_key ~= nil and string.len(g_key) > 0 and collection_utils.array_in(ups_group, g_key) then
			if value ~= nil then
				local g_key_len = string.len(g_key)
	        	for k, v in pairs(value) do
	        		local k_sufix = string.sub(k, (0 - g_key_len))

	        		if k ~= nil and string.len(k) > (g_key_len + 2) and g_key == string.sub(k, (0 - g_key_len)) then
	        			local s_name = string.sub(k, 1, (-2 - g_key_len))
	        			local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_name},":")
	        			local hash_key = "_" .. g_key
	        			local ok, err = redis:hmset(service_key, hash_key, cjson.encode(v))
	        			if err ~= nil then
	        				ngx.log(ngx.ERR, string.format("Error when save ups[%s] to redis. err: %s", hash_key, cjson.encode(err)))
	        			end
	        		end
	        	end
	        end
			return 3
		end

		local result = 4
		if value ~= nil then
			for k, v in pairs(value) do
				repeat
					local last_index = string_utils:last_indexof(k, "_")
		        	if last_index == nil or last_index < 1 or last_index == string.len(k) then
		    			break;
		    		end

		    		local s_name = string.sub(k, 1, last_index - 1)
		    		local g_name = string.sub(k, last_index + 1, string.len(k))
		    		if collection_utils.array_in(ups_group, g_name) then
		    			local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_name},":")
	        			local hash_key = "_" .. g_name
	        			local ok, err = redis:hmset(service_key, hash_key, cjson.encode(v))
	        			if err ~= nil then
	        				ngx.log(ngx.ERR, string.format("Error when save ups[%s] to redis. err: %s", hash_key, cjson.encode(err)))
	        				result = -1
	        			end
		    		end
				until true
	        end
	        return result
		end
		return -1
	end
	return -1;
end

return _M