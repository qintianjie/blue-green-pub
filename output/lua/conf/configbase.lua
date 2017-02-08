local modulename = "bgpub.configbase"
local _M = {}
_M._VERSION = '1.0.0'

_M.kk="base"


_M.redisConf = {
    -- ["server"]    = "192.168.142.128:6379:123456,192.168.142.128:6378:123456" , -- ip:port:auth 格式
    ["server"]    = "127.0.0.1:6379:123456,192.168.142.128:6378:123456" , -- ip:port:auth 格式
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


_M.ups_group = {"g1", "g2"} 

_M.fields = {
    -- ['switch']           = 'switch',
    -- ['optype']           = 'optype',
    -- ['opdata']           = 'opdata'
    ['switch']           = 'graySwitch',
    ['optype']           = 'grayType',
    ['opdata']           = 'grayData',

    ['server_size']      = 'server_size'
}

_M.optypes = {
    ["uidin"]        = 'uidin',
    ["uidmod"]       = 'uidmod',
    ["unamein"]      = 'unamein'
} 

_M.switch_enum = {
    ['test']          = 'TEST',  -- for test
    ['online_auto']   = 'ONLINE_AUTO', -- for online, auto load balance between blue and green upstream
    -- ['online_manual'] = 'ONLINE_MANUAL',
    ['close']         = 'CLOSE'
}


return _M
