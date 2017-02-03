-- 蓝绿发布 API 接口层.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "api.bluegreen"
local _M = {}
_M._VERSION = '1.0.0'

local bluegreen_biz    = require("biz.bluegreen_biz")
local collection_utils = require("utils.collection_utils")
local config_base 	   = require("configbase")
local switch_enum      = config_base.switch_enum

local upstream = require "ngx.upstream"
local add_server = upstream.add_server

-- local upstream 		   = require ("ngx.upstream")
-- local string_utils     = require ("utils.string_utils")

-- 根据传入的 service_name ，从 redis 取相关规则数据，设置到 shared dict 中
-- conf = {["s_key":xxx]} : s_key ==> 传入的服务名，可以逗号分隔为多个
_M.ruleset = function ( self, conf )
	-- local service_keys = conf.s_key
	local ok, err = bluegreen_biz.ruleset(conf)
	return ok, err
end

_M.ruleget = function ( self, conf )
	local result = bluegreen_biz.ruleget(conf)
	return result, "succeed get rule data limit 100."
end

_M.ruledelete = function ( self, conf )
	-- local service_keys = conf.s_key
	local ok, err = bluegreen_biz.ruledelete(conf)
	return ok, err
end

-- update switch for a service
_M.switchupdate = function ( self, conf )
	if collection_utils.containKey(switch_enum, string.lower(conf.switch_value)) then
		local ok, err = bluegreen_biz.switchupdate(conf)
		return ok, err
	else
		return "-1", "switch value invalid."
	end
end

-- display all upstream and it's servers
_M.upstream_get = function ( self, conf )
	local result = bluegreen_biz:upstream_get(conf)
	return result
end

_M.upstream_save_to_redis = function ( self, conf )
	local result = bluegreen_biz:upstream_get(conf)
	conf["value"] = result
	return bluegreen_biz:upstream_save_to_redis(conf)
end

_M.init_worker = function (self) 

	local handler_when_start
	-- do work when start or reload nginx, only one work do it.
	handler_when_start = function ( )
		ngx.log(ngx.ERR, "=====> init work for work 0")
		local concat = table.concat
        local upstream = require "ngx.upstream"
        local get_servers = upstream.get_servers
        local get_upstreams = upstream.get_upstreams
        
        local us = get_upstreams()
        for _, u in ipairs(us) do
        	ngx.log(ngx.ERR, "------> ups: " .. u)
        end
	end

	if ngx.worker.id() == 0 then
		ngx.timer.at(0, handler_when_start) 
	end 

	local delay_schedule = 5  -- 3s
	local handler_schedule
	-- do work for each worker, such as change upstream server for each worker
	handler_schedule = function ()
		-- local conf = {["s_key"] = s_key, ["g_key"] = g_key}
		-- local bluegreen_biz    = require("biz.bluegreen_biz")
        local result = bluegreen_biz:upstream_get({})
        local upsMap = {}
        if result ~= nil then
        	for k, v in pairs(result) do
        		upsMap[k] = v
        	end
    	end

	 	-- ngx.log(ngx.ERR, "========> schedule for each worker.")
		local concat = table.concat
        local upstream = require "ngx.upstream"
        local get_servers = upstream.get_servers
        local get_upstreams = upstream.get_upstreams
        
        local us = get_upstreams()
        for _, u in ipairs(us) do
        	repeat
        		if collection_utils.containKey(result, u) then
	        		local upsServerList = upsMap[u]
	        		-- ngx.log(ngx.ERR, "------> ups[".. ngx.worker.id() .. "]: " .. k .. ", v: " .. u .. "; ups: " .. cjson.encode(upsServerList))

	        		for sk, sv in pairs(upsServerList) do
	        			-- ngx.log(ngx.ERR, u .. "---k: " .. sk .. ", v: " .. cjson.encode(sv) .. ", ADDR: " .. sv["addr"])
	        			
	        			local abc = function () 
	        				return -1, "exist" 
	        			end
	        			-- ngx.log(ngx.ERR, "---> " .. sv["addr"])
			            -- local add_server = upstream.add_server
			            local ret, ok,err = xpcall(add_server(u, sv["addr"], 1, 1, 10, false), abc)
			            if ret ~= nil and ret then
			            	ngx.log(ngx.ERR, "====================> " .. tostring(ret) .. " : ok: " .. ok)
			            else
			            	-- ngx.log(ngx.ERR, "-----> " .. tostring(ret) .. " : ok: " .. ok)
			            end
			            
	        		end
	        		-- ngx.log(ngx.ERR, "----u done. u: " .. u)
	        	else
	        		break
	        	end
        	until true
        end

	    local ok, err = ngx.timer.at(delay_schedule, handler_schedule)
	    if not ok then
	        ngx.log(ngx.ERR, "failed to create the timer: ", err)
	        return
	    end
	end

	local ok, err = ngx.timer.at(delay_schedule, handler_schedule)
	 if not ok then
	     ngx.log(ngx.ERR, "failed to create the timer: ", err)
	     return
	 end
end

return _M