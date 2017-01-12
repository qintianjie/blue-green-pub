

# blue-green-pub

git clone xxxx   
./package.sh [dev|prod|qa]  
  
then main.lua   

# nginx		
---		
put nginx/conf  the a new openresty/nginx	
nginx -t   
nginx -s reload  

curl http://127.0.0.1:8080/echo?name=1  
curl http://127.0.0.1:8080/echo?name=2  


# Dynamic upstream  
https://github.com/qintianjie/gray-pub/blob/master/docs/dynamic%20upstream.md 

# CMDs
```
git clone https://github.com/qintianjie/blue-green-pub.git
cd blue-green-pub/output

root@jackqin /opt/dev/lua/blue-green-pub/output $pkill -9 nginx; rm -rf *temp; rm -rf logs/*; nginx -p `pwd`
root@jackqin /opt/dev/lua/blue-green-pub/output $curl "http://localhost:8899/bgpub/ruleset?service=apollo"
done 200
root@jackqin /opt/dev/lua/blue-green-pub/output $curl "http://localhost:8899/bgpub/get/all"
{"biztech:gray:apollo:grayData":"111,222,333","biztech:gray:apollo:graySwitch":"true","biztech:gray:apollo:grayType":"in"}

```
