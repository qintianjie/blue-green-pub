local modulename = "graypub.config"
local _M = {}
_M._VERSION = '1.0.0'

_M.k1="dev_v1"

-- redis 相关配置
_M.redis_host="192.168.142.128:6378:123456,192.168.142.128:6379:123456" -- ip:port:auth 格式


return _M
