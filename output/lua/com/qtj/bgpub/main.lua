local project_path = "/opt/dev/lua/blue-green-pub/" 
 
local package_path = package.path  
package.path = string.format("%s;%s?.lua;%sconf/?.lua;%s/src/?.lua;%ssrc/lib/?.lua;%sinit.lua",
        package_path, project_path, project_path, project_path, project_path, project_path)  

-- print("path: " .. package.path)

-- local configbase = require("configbase")
-- local config = require("config")

-- print("kk: " .. configbase["kk"])
-- print("k1: " .. config["k1"])

-- print("path: " .. package.path)

-- -- local redis_dal=require("dal.redis_dal")

-- -- if redis_dal == nil then
-- -- 	print ("nillll")
-- -- else
-- -- 	print("good")
-- -- 	redis_dal.conn()
-- -- end

-- local cjson = require "cjson"
local data = {}
rawset(data, "id1", "val1")
rawset(data, "id2", "val2")

local sn = "abc_g1_g2"
local li = sn:match('^.*()' .. "/")
if li ~= nil  then
	local re =string.sub(sn, 1, li - 1)
	print("done: " .. li .. ", re: " .. re)
else
	print("no sn sub")
end

local arr = {"_g1", "_g2"}


print(string.sub(sn, 1, -2))
print ("abc" == "abc")
sn = ''
print("sn.len: " .. string.len(sn) .. ", " .. #sn)


local myfun = function ( )
	local a = tonum(12)
	return a
end
local function __TRACKBACK__(msg)
	print ("wakka: " .. msg)
	return -1
end
-- local b = xpcall(myfun(), __TRACKBACK__())
local ret, msg = xpcall(myfun, __TRACKBACK__())
print("b: " .. msg .. ", status: " .. tostring(ret))

