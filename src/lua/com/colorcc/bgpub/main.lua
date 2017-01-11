local project_path = "/opt/dev/lua/blue-green-pub/" 
 
local package_path = package.path  
package.path = string.format("%s;%s?.lua;%sconf/?.lua;%s/src/?.lua;%ssrc/lib/?.lua;%sinit.lua",
        package_path, project_path, project_path, project_path, project_path, project_path)  

print("path: " .. package.path)

local configbase = require("configbase")
local config = require("config")

print("kk: " .. configbase["kk"])
print("k1: " .. config["k1"])

print("path: " .. package.path)

-- local redis_dal=require("dal.redis_dal")

-- if redis_dal == nil then
-- 	print ("nillll")
-- else
-- 	print("good")
-- 	redis_dal.conn()
-- end

print("done")

