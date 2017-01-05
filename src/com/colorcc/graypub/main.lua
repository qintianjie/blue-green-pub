local p = "/opt/dev/lua/gray-pub/" 
 
local m_package_path = package.path  
package.path = string.format("%s;%s?.lua;%sconf/?.lua;%sinit.lua;%s*/?.lua",m_package_path, p, p, p, p)  

local configbase = require("configbase")
local config = require("config-dev")
print("kk: " .. configbase["kk"])
print("k1: " .. config["k1"])

print("path: " .. package.path)

