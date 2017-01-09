-- A test sample.
--
-- Author: qintianjie
-- Date:   2017-01-05

local modulename = "dal.redis"
local _M = {}
_M._VERSION = '1.0.0'

local redis = require "resty.redis"


function _M.conn(self)
	local red = redis:new()
	red:set_timeout(1000) 
	local ok, err = red:connect("127.0.0.1", 6379)
    	if not ok then
    		print("error eonnect to redis")
    	else
    		print("good to redis")
        -- ngx.log(ngx.ERR, "failed to connect to redis: ", err)
        -- return ngx.exit(500)
    	end

	print ("use redis")
end 

return _M