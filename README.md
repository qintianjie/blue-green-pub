
# run sample:
```
1. install redis. eg:  192.168.142.128:6379, auth=123456
2. set data:
    HMSET biztech:gray:apollo graySwitch true grayType in grayData 111,222,333
    HGETALL biztech:gray:apollo
    
    SADD biztech:gray:service:names apollo atlas
    SMEMBERS biztech:gray:service:names
    
3. git clone https://github.com/qintianjie/blue-green-pub.git
   cd blue-green-pub/output
   
4. pkill -9 nginx; rm -rf *temp; rm -rf logs/*; nginx -p `pwd`
   curl "http://localhost:8899/bgpub/ruleset?service=ss,apollo,aka"
   curl "http://localhost:8899/bgpub/ruleget?service=apollo"
   curl "http://localhost:8899/bgpub/switchupdate?service=apollo&switch=TEST"
   curl "http://localhost:8899/bgpub/ruledelete?service=apollo"
   curl "http://localhost:8899/bgpub/ups/get?service=backend&group=g1"
   tail -f logs/*log
   
Tips:  change redis config from lua/conf/configbase.lua
```
![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/blue_green_action.png)
![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/blue_green_action_get_ups.png)

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
