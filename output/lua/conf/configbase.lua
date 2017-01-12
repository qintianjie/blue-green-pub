local modulename = "bgpub.configbase"
local _M = {}
_M._VERSION = '1.0.0'

_M.kk="base"


_M.redisConf = {
    ["server"]    = "192.168.142.128:6379:123456,192.168.142.128:6378:123456" , -- ip:port:auth 格式
    ["poolsize"] 		= 100, 
    ["idletime"] 		= 50000 , 
    ["timeout"]  		= 60000,
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