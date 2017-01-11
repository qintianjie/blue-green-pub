-- A test sample.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "dal.redis"
local _M = {}
_M._VERSION = '1.0.0'

local redis = require "resty.redis"
local string_utils = require "utils.string_utils"

_M.new = function(self, conf)
	self.server     = conf.server
    self.timeout    = conf.timeout
    self.dbid       = conf.dbid
    self.poolsize   = conf.poolsize
    self.idletime   = conf.idletime

    local red = redis:new()
    return setmetatable({redis = red}, { __index = _M } )
end

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
        timeout = 1000   -- 10s
    end

    red:set_timeout(timeout)

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
                    -- if ok then return red:select(dbid) end
                    if ok then
                        local auth_ok, auth_err
                        if r_auth and r_auth ~= '' then
                            auth_ok, auth_err = red:auth(r_auth)
                            if auth_ok then
                                return red:select(dbid)
                            else
                                return auth_ok, auth_err
                            end
                        else
                          return red:select(dbid)
                        end
                    else
                    	return ok, err
                    end
                end
            end
    	end
    end
    return nil, "connect redis error."
end


-- function _M.conn(self)
-- 	local red = redis:new()
-- 	red:set_timeout(1000) 
-- 	local ok, err = red:connect("127.0.0.1", 6379)
-- 	if not ok then
-- 		print("error eonnect to redis")
-- 		return "-1"
-- 	else
-- 		print("good to redis")
-- 		return "1"
-- 	end
-- end 

_M.keepalivedb = function(self)
    local   pool_max_idle_time  = self.idletime --毫秒
    local   pool_size           = self.poolsize --连接池大小

    if not pool_size then pool_size = 1000 end
    if not pool_max_idle_time then pool_max_idle_time = 90000 end
    
    return self.redis:set_keepalive(pool_max_idle_time, pool_size)  
end

return _M