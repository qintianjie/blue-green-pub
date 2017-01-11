local modulename = "bgpub.configbase"
local _M = {}
_M._VERSION = '1.0.0'

_M.kk="base"


-- _M.redis_server="192.168.142.128:6378:123456,192.168.142.128:6379:123456" -- redis host 信息:  ip:port:auth 格式
-- _M.redis_dbid=0
-- _M.redis_poolsize=100
-- _M.redis_idletime=50000
-- _M.redis_timeout=500000
-- redis 相关配置
_M.redisConf = {
    ["server"]    = "192.168.142.128:6379:123456,192.168.142.128:6378:123456" , -- ip:port:auth 格式
    ["poolsize"] 		= 100, 
    ["idletime"] 		= 50000 , 
    ["timeout"]  		= 500000,
    ["dbid"]     		= 0
}

_M.redisInitService = {
    ["initServiceName"]  = "bgpub:service:names"
}

_M.prefixConf = {
    ["policyPrefix"]     = 'biztech:gray'
    -- ["policyPrefix"]     = 'bizgray'
} 

_M.fields = {
    -- ['switch']           = 'switch',
    -- ['optype']           = 'optype',
    -- ['opdata']           = 'opdata'
    ['switch']           = 'graySwitch',
    ['optype']           = 'grayType',
    ['opdata']           = 'grayData'
}


return _M