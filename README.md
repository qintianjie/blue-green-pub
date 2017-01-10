# gray-pub

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
