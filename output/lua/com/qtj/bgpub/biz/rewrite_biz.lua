local config_base 	= require("configbase")
local collection_utils =  require("utils.collection_utils")

local rule_data_cache = ngx.shared["dict_rule_data"]

-- service name
local s_key = ngx.var._S_ID


-- get uid in request and change to number, if none or invalid, make it to default [ 0 ]
local s_uname = ngx.req.get_headers()["uname"]
if not s_uname or string.len(s_uname) == 0 then s_uname = ngx.var.cookie_uname end
if not s_uname or string.len(s_uname) == 0 then s_uname = ngx.req.get_uri_args()["uname"] end

local s_uid = tonumber(ngx.req.get_headers()["uid"])
if not s_uid or s_uid < 0 then s_uid = tonumber(ngx.var.cookie_uid) end
if not s_uid or s_uid < 0 then s_uid = tonumber(ngx.req.get_uri_args()["uid"]) end

if not s_uname and not s_uid then
  ngx.log(ngx.ERR, "[API_rewrite] Invalid uid/uname for both are nil. Set it to default [ uid: 0, uname =  ]")
end
if not s_uname then s_uname = "" end
if not s_uid   then s_uid = 0 end

-- biztech:gray:xxxx   (s_key: xxxx, will be apollo, atlas etc.)
local service_key = table.concat({config_base.prefixConf["policyPrefix"],s_key},":")

-- get service switch from lua dict
local gray_rule_cache = ngx.shared["dict_rule_data"]
local service_switch = gray_rule_cache:get(service_key .. ":" .. config_base.fields["switch"])

if service_switch == nil or service_switch == false then
	ngx.var._UPS = s_key
else
	local g1_key = service_key .. ":_g1"
	local g2_key = service_key .. ":_g2"
	local ups_g1_size = gray_rule_cache:get(g1_key)
	local ups_g2_size = gray_rule_cache:get(g2_key)
	if ups_g1_size == nil then ups_g1_size = 0 end
	if ups_g2_size == nil then ups_g2_size = 0 end


	if ups_g1_size == 0 and ups_g2_size == 0 then
		ngx.var._UPS = s_key
	end


	local ups_g1_name = s_key .. "_g1"
	local ups_g2_name = s_key .. "_g2"

	-- if no uid or switch is close, visit the more server upstream
	if (s_uid == 0 and s_uname = "") or string.lower(service_switch) == "close" then
		if ups_g1_size < ups_g2_size then 
			ngx.var._UPS = ups_g2_name
		else
			ngx.var._UPS = ups_g1_name
		end
		return
	end

	-- test: do it by rule
	if string.lower(service_switch) == "test" then
		local optype = gray_rule_cache:get(service_key .. ":" .. config_base.fields["optype"])
		local opdata = gray_rule_cache:get(service_key .. ":" .. config_base.fields["opdata"])
		if not collection_utils.containKey(config_base.optypes, optype)  then
			optype = "uidin"
		end
		local policy = require("policy.policy_" .. optype)
		local params = {}

		params["uid"]         = s_uid
		params["uname"]       = s_uname
		params["rule_data"]   = opdata
		params["ups_g1_size"] = ups_g1_size
		params["ups_g2_size"] = ups_g2_size
		params["ups_g1_name"] = ups_g1_name
		params["ups_g2_name"] = ups_g2_name

		local ups = policy.process(params)

		ngx.var._UPS = ups
	elseif string.lower(service_switch) == "online_auto" then -- do it auto
		local policy = require("policy.policy_online_auto")
		local params = {}
		params["uid"]         = s_uid
		params["uname"]       = s_uname
		params["rule_data"]   = opdata
		params["ups_g1_size"] = ups_g1_size
		params["ups_g2_size"] = ups_g2_size
		params["ups_g1_name"] = ups_g1_name
		params["ups_g2_name"] = ups_g2_name

		local ups = policy.process(params)

		ngx.var._UPS = ups

		-- if ups_g1_size == 0 then 
		-- 	ngx.var._UPS = ups_g2_name
		-- elseif ups_g2_size == 0 then
		-- 	ngx.var._UPS = ups_g1_name
		-- else
		-- 	local server_size = ups_g1_size + ups_g2_size
		-- 	local userid_num = tonumber(s_uid)
		-- 	if userid_num ~= nil and userid_num > 0 and userid_num % server_size < ups_g1_size then
		-- 		ngx.var._UPS = ups_g1_name
		-- 	else
		-- 		ngx.var._UPS = ups_g2_name
		-- 	end
		-- end
	else -- default is close
		if ups_g1_size < ups_g2_size then 
			ngx.var._UPS = ups_g2_name
		else
			ngx.var._UPS = ups_g1_name
		end
	end
end

-- ngx.var._UPS = "apollo_g2"
