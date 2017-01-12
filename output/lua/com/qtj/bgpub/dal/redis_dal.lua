-- A test sample.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "dal.redis"
local _M = {}
_M._VERSION = '1.0.0'

local redis = require "resty.redis"
local string_utils = require "utils.string_utils"

-- redis 配置信息初始化
_M.new = function(self, conf)
	self.server     = conf.server  -- ip1:port1:auth1,ip2:port2:auth2 格式
    self.timeout    = conf.timeout
    self.dbid       = conf.dbid
    self.poolsize   = conf.poolsize
    self.idletime   = conf.idletime

    local red = redis:new()
    return setmetatable({redis = red}, { __index = _M } )
end

-- redis 连接操作
-- 1. 根据逗号(",")分隔 server -->  {[ip1, port1, auth1], [ip2, port2, auth2] }
-- 2. 一次对每组 ip:port:auth 执行
--    2.1  red:connect(host, port)
--    2.2  判断是否需要 auth 验证，如需要执行 redis:auth(aut)
--    2.3  如连接成功，执行  red:select(dbid) 选择一个库，返回
-- 3. 如步骤2连接不上，则选择下一组 server 重复2 直到成功，或者都失败

-- 成功则返回 red, msg
-- 失败返回   nil, msg

-- @TODO: 记录连接成功的 server 到缓存，下次直接用成功的先处理，不行再循环这些 server 列表
_M.connectdb = function(self)
    local server  = self.server
    local dbid    = self.dbid
    local red     = self.redis
    local timeout = self.timeout

    if not server then 
    	return nil, "No redis configuration."
    end

    if not dbid then dbid = 0 end

    local timeout   = self.timeout 
    if not timeout then 
        timeout = 1000   -- 1s
    end
    
    red:set_timeout(timeout) --ms


    local server_arr = string_utils.split(server, ",")
    for i = 1, #server_arr do  
    	local server_item = server_arr[i]
    	if (string.len(server_item) > 0) then
    		local item = string_utils.split(server_item, ":")
            if (#item == 3) then
                local r_host = item[1]
                local r_port = item[2]
                local r_auth = item[3]
                if r_host and r_port then
                    ok, err = red:connect(r_host, r_port)
                    if ok then
                        local auth_ok, auth_err
                        if r_auth and r_auth ~= '' then
                            auth_ok, auth_err = red:auth(r_auth)
                            if auth_ok then
                                -- @TODO 保存成功信息
                                -- red:select(dbid)
                                -- return red, "SUCCEED with auth"
                                return red:select(dbid)
                            else
                                return auth_ok, auth_err
                                -- return nil, "auth failed."
                            end
                        else
                          -- @TODO 保存成功信息
                          return red:select(dbid)
                          -- return red, "SUCCEED without auth"
                        end
                    end
                end
            end
    	end
    end
    return nil, "connect redis error."
end

-- 设置 keepalive
_M.keepalivedb = function(self)
    local   pool_max_idle_time  = self.idletime --毫秒
    local   pool_size           = self.poolsize --连接池大小

    if not pool_size then pool_size = 1000 end
    if not pool_max_idle_time then pool_max_idle_time = 90000 end
    
    return self.redis:set_keepalive(pool_max_idle_time, pool_size)  
end

return _M