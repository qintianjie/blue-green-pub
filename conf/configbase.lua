local modulename = "graypub.configbase"
local _M = {}
_M._VERSION = '1.0.0'

_M.kk="base"

-- redis 相关配置
_M.redis_host="192.168.142.128:6378:123456,192.168.142.128:6379:123456" -- redis host 信息:  ip:port:auth 格式
_M.redis_dbid=0
_M.redis_poolsize=100
_M.redis_idletime=50000
_M.redis_timeout=500000

return _M