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

-- -- display all upstream and it's servers
-- _M.upstream_get = function ( self, conf )
-- 	local result = bluegreen_biz:upstream_get(conf)
-- 	return result
-- end

-- _M.upstream_save_to_redis = function ( self, conf )
-- 	local result = bluegreen_biz:upstream_get(conf)
-- 	conf["value"] = result
-- 	return bluegreen_biz:upstream_save_to_redis(conf)
-- end

_M.init_worker = function (self) 
	bluegreen_biz.init_worker(self)
end

return _M