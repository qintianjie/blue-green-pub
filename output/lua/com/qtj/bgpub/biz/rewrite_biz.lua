local config_base 	= require("configbase")
local collection_utils =  require("utils.collection_utils")

local rule_data_cache = ngx.shared["dict_rule_data"]

-- service name
local s_key = ngx.var._S_ID

-- 获得 uid & uname 值，顺序为 heaer -> cookie --> request params
-- 取 uanme
local s_uname = ngx.req.get_headers()["uname"]
if not s_uname or string.len(s_uname) == 0 then s_uname = ngx.var.cookie_uname end
if not s_uname or string.len(s_uname) == 0 then s_uname = ngx.req.get_uri_args()["uname"] end

-- 取 uid
local s_uid = tonumber(ngx.req.get_headers()["uid"])
if not s_uid or s_uid < 0 then s_uid = tonumber(ngx.var.cookie_uid) end
if not s_uid or s_uid < 0 then s_uid = tonumber(ngx.req.get_uri_args()["uid"]) end

-- 如果 uid & uname 不存在，打印一条日志，并设置其为默认值
if not s_uname and not s_uid then
  ngx.log(ngx.ERR, "[API_rewrite] Invalid uid/uname for both are nil. Set it to default [ uid: 0, uname =  ]")
end
if not s_uname then s_uname = "" end
if not s_uid   then s_uid = 0 end

-- 构造dict的 key 值。 格式：biztech:gray:xxxx   (s_key: xxxx, will be apollo, atlas etc.)
local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_key},":")

-- get service switch from lua dict
local gray_rule_cache = ngx.shared["dict_rule_data"]
local service_switch = gray_rule_cache:get(service_key .. ":" .. config_base.fields["switch"])

-- 如果没有 switch，则访问 名为 service_name 的 upstream
if service_switch == nil or service_switch == false then
	ngx.var._UPS = s_key
else
	-- 取 dict 中 upstream 每组 server 数量
	local g1_key = service_key .. ":_g1"
	local g2_key = service_key .. ":_g2"
	local ups_g1_size = gray_rule_cache:get(g1_key)
	local ups_g2_size = gray_rule_cache:get(g2_key)
	if ups_g1_size == nil then ups_g1_size = 0 end
	if ups_g2_size == nil then ups_g2_size = 0 end

	-- 如果两组 upstream 里的 server 均为0，则访问名为 service_name 的 upstream
	if ups_g1_size == 0 and ups_g2_size == 0 then
		ngx.var._UPS = s_key
	end

	-- 定义的 upstream 名称
	local ups_g1_name = s_key .. "_g1"
	local ups_g2_name = s_key .. "_g2"

	-- 如果没有 uid 或者 switch 值为 close，说明走老的逻辑，也就是访问线上机器，那么就把流量都打到 server 多的 upstream 里
	if (s_uid == 0 and s_uname == "") or string.lower(service_switch) == "close" then
		if ups_g1_size < ups_g2_size then 
			ngx.var._UPS = ups_g2_name
		else
			ngx.var._UPS = ups_g1_name
		end
		return
	end

	-- 构造请求参数，供后续规则处理用
	local params = {}
	params["uid"]         = s_uid
	params["uname"]       = s_uname
	params["ups_g1_size"] = ups_g1_size
	params["ups_g2_size"] = ups_g2_size
	params["ups_g1_name"] = ups_g1_name
	params["ups_g2_name"] = ups_g2_name

	-- 如果 switch: gray , 则取灰度规则，满足规则的流量打到机器少的 server 中
	if string.lower(service_switch) == "test" then
		local optype = gray_rule_cache:get(service_key .. ":" .. config_base.fields["optype"])
		local opdata = gray_rule_cache:get(service_key .. ":" .. config_base.fields["opdata"])

		params["rule_data"]   = opdata
		
		if not collection_utils.containKey(config_base.optypes, optype)  then
			optype = "uidin"
		end
		-- 灰度规则对应的策略，包括： uidin, uidmod, unmaein
		local policy = require("policy.policy_" .. optype)
		local ups = policy.process(params)

		-- 得到最终要经过的 upstream
		ngx.var._UPS = ups

	-- 如果 switch: auto，代表上线，此刻采用自动流量切分。 即 uid % (g1 + g2) < g1， 让流量与分组成正比
	elseif string.lower(service_switch) == "online_auto" then -- do it auto
		local policy = require("policy.policy_online_auto")
		local ups = policy.process(params)
		ngx.var._UPS = ups

	-- 其他情况， 流量走 server 多的 upstream
	else 
		if ups_g1_size < ups_g2_size then 
			ngx.var._UPS = ups_g2_name
		else
			ngx.var._UPS = ups_g1_name
		end
	end
end