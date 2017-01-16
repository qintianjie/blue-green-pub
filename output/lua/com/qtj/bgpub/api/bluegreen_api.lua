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

local upstream 		   = require ("ngx.upstream")
local string_utils     = require ("utils.string_utils")

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
	if collection_utils.containKey(switch_enum, conf.switch_value) then
		local ok, err = bluegreen_biz.switchupdate(conf)
		return ok, err
	else
		return "-1", "switch value invalid."
	end
end

-- display all upstream and it's servers
_M.upstream_get = function ( self, conf )
    local ups = upstream.get_upstreams()

    local get_servers = upstream.get_servers

    local servicename = conf.s_key
    local ups_list = {}
    ngx.log(ngx.ERR, "service: " .. servicename)

    for _, u in ipairs(ups) do
    	repeat 

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

	        local srvs, err = get_servers(u)

	        if not srvs then
	            ngx.log(ngx.ERR, string.format("no server for upstream %s", u))
	        else 
	        	 for _, srv in ipairs(srvs) do
	        	 	ngx.print("ups: " .. u .. " => ")
		 	        local first = true
	                for k, v in pairs(srv) do
	                    if first then
	                        first = false
	                        ngx.print("    ")
	                    else
	                        ngx.print(", ")
	                    end
	                    if type(v) == "table" then
	                        ngx.print(k, " = {", concat(v, ", "), "}")
	                    else
	                        ngx.print(k, " = ", v)
	                    end
	                end
	                ngx.print(";\n")
	        	 end
	        end
    	until true
    end
end

_M.init_worker = function (self) 
	if ngx.worker.id() == 0 then
		local pfunc = function ()
			ngx.log(ngx.ERR, "=====> init work for work 0")
			local concat = table.concat
            local upstream = require "ngx.upstream"
            local get_servers = upstream.get_servers
            local get_upstreams = upstream.get_upstreams
            
            local us = get_upstreams()
            for _, u in ipairs(us) do
            	ngx.log(ngx.ERR, "=====> ups: " .. u)
                -- ngx.say("upstream ", u, ":")
                -- local srvs, err = get_servers(u)
                -- if not srvs then
                --     ngx.say("failed to get servers in upstream ", u)
                -- else
                --     for _, srv in ipairs(srvs) do
                --         local first = true
                --         for k, v in pairs(srv) do
                --             if first then
                --                 first = false
                --                 ngx.print("    ")
                --             else
                --                 ngx.print(", ")
                --             end
                --             if type(v) == "table" then
                --                 ngx.print(k, " = {", concat(v, ", "), "}")
                --             else
                --                 ngx.print(k, " = ", v)
                --             end
                --         end
                --         ngx.print("\\n")
                --     end
                -- end
            end

		--     local code, data =  bizSetDataModule:getGrayServiceNames()
		--     if code ~= 200 then
		-- 		ngx.log(ngx.ERR, "[API_init_worker] error: ", data)
		--     else
		-- 	    local value = "";
		-- 	    for k, v in pairs(data) do
		-- 	    	value = value .. v .. ","
		-- 	    end
		-- 	    value=string.sub(value, 1, -2)
		-- 	    local conf = {["s_key"] = value }
		-- 	    ngx.log(ngx.INFO, "[API_init_worker] init service : [" .. value .. "]")
		-- 	  	return bizSetDataModule:setRedisDataToDict(conf)
		--     end
		end
		  
		ngx.timer.at(0, pfunc) 
	end
end

return _M