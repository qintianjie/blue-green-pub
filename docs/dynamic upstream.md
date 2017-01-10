# install  
``` 
git clone https://github.com/CNSRE/lua-upstream-nginx-module.git  
wget https://openresty.org/download/openresty-1.11.2.2.tar.gz  

git clone https://github.com/cubicdaiya/ngx_dynamic_upstream.git // 另外一种 dynamic upstream, 类似 nginx plus


tar -zxvf openresty-1.11.2.2.tar.gz   
cd openresty-1.11.2.2   
rm -rf build/ngx_lua_upstream-0.06/*     (except "config",  保留 config 文件)    
cp lua-upstream-nginx-module/* openresty-1.11.2.2/build/ngx_lua_upstream-0.06/   (except "config", 不拷贝 config 文件)   

// ./configure -j2   
./configure --add-module=/opt/dev/nginx-module/ngx_dynamic_upstream -j2
make -j2   
make install  
```

# Verify   
```
nginx -V  

root@jackqin /opt/software/nginx/openresty-1.11.2.2 $nginx -V
nginx version: openresty/1.11.2.2
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-11) (GCC) 
built with OpenSSL 1.0.1e-fips 11 Feb 2013
TLS SNI support enabled
configure arguments: --prefix=/usr/local/openresty/nginx --with-cc-opt=-O2 --add-module=../ngx_devel_kit-0.3.0 --add-module=../echo-nginx-module-0.60 --add-module=../xss-nginx-module-0.05 --add-module=../ngx_coolkit-0.2rc3 --add-module=../set-misc-nginx-module-0.31 --add-module=../form-input-nginx-module-0.12 --add-module=../encrypted-session-nginx-module-0.06 --add-module=../srcache-nginx-module-0.31 --add-module=../ngx_lua-0.10.7 --add-module=../ngx_lua_upstream-0.06 --add-module=../headers-more-nginx-module-0.32 --add-module=../array-var-nginx-module-0.05 --add-module=../memc-nginx-module-0.17 --add-module=../redis2-nginx-module-0.13 --add-module=../redis-nginx-module-0.3.7 --add-module=../rds-json-nginx-module-0.14 --add-module=../rds-csv-nginx-module-0.07 --with-ld-opt=-Wl,-rpath,/usr/local/openresty/luajit/lib --add-module=/opt/dev/nginx-module/ngx_dynamic_upstream --with-http_ssl_module
```
