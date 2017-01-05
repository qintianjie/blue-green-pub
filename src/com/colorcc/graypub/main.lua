local project_path = "/opt/dev/lua/gray-pub/" 
 
local package_path = package.path  
package.path = string.format("%s;%s?.lua;%sconf/?.lua;%s/src/?.lua;%sinit.lua",
        package_path, project_path, project_path, project_path, project_path)  

local configbase = require("configbase")
local config = require("config")
print("kk: " .. configbase["kk"])
print("k1: " .. config["k1"])

print("path: " .. package.path)

