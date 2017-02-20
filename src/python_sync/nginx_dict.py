# coding=utf-8
'''
Created on Feb 15, 2017

@author: qtj
'''
import ConfigParser
import json
import threading
from time import sleep
import time
import urllib2

import redis
import threadpool

import logging as LOGGER
# from logging.handlers import TimedRotatingFileHandler
import datetime

LOG_FILE = "/opt/service/bizgray/logs/gray_sync.log"
LOGGER.basicConfig(level=LOGGER.DEBUG,
                format='%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',
#                 datefmt='%a, %d %b %Y %H:%M:%S',
                filename=LOG_FILE,
                filemode='w') 

# hdlr = TimedRotatingFileHandler(LOG_FILE, when='M', interval=1, backupCount=40)
# hdlr.setLevel(LOGGER.DEBUG)
# formatter = LOGGER.Formatter('%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s')
# hdlr.setFormatter(formatter)
#  
# LOGGER.getLogger('').addHandler(hdlr)


class NginxDict():
    '''
    classdocs
    '''
    cf = None
    redis_conf = {}
    nginx_server = {}
    ups_conf = {}
    
    def __init__(self, params):
        '''
        Constructor
        '''
        LOGGER.debug("init nginx dict class.")
        cf = ConfigParser.ConfigParser()
        cf.read("sync.properties")
        self.cf = cf
        
        self.redis_conf["host"] = cf.get("redis", "host")
        self.redis_conf["port"] = cf.getint("redis", "port")
        self.redis_conf["db"] = cf.getint("redis", "db")
        self.redis_conf["auth"] = cf.get("redis", "auth")
        self.redis_conf["key_prefix"] = cf.get("redis", "key_prefix")
        
        self.nginx_server["host"] = cf.get("server", "host")
        self.nginx_server["port"] = cf.get("server", "port")
        self.nginx_server["ip_port"] = self.nginx_server["host"] + ":" + self.nginx_server["port"]
        
        self.ups_conf["ups_file_path_prefix"] = cf.get("upstream", "ups_file_path_prefix")
               
    # redis 数据同步到 nginx 中去. 同步得数据包括：
    # 1. 规则数据
    # 2. upstream 里 server 列表   
    def redis_sync_nginx(self, params):
        r = self.__init_redis()
        
        # 根据服务名取 redis 分组机器信息
        # 过滤 down 设置的 server， 得到线上应该有的机器列表
        serviceName = params['sn']
        redis_service_key = self.redis_conf["key_prefix"] + serviceName
        
        g1Content = r.hget(redis_service_key, "_g1")
        g1Json = None
        if g1Content != None:
            g1Json = json.loads(g1Content)
        else:
            LOGGER.debug("[TIPS] " + redis_service_key + ":_g1 content is None.")
        
        g2Content = r.hget(redis_service_key, "_g2")
        g2Json = None
        if g2Content != None:
            g2Json = json.loads(g2Content) 
        else:
            LOGGER.debug("[TIPS] " + redis_service_key + ":_g2 content is None.")
        
        # 同步规则数据到  nginx lua dict 中 
        self.__sync_nginx_luadict(serviceName)
        # 同步 server 到 upstream
        self.__sync_nginx_upstream(serviceName, "g1", g1Json)
        self.__sync_nginx_upstream(serviceName, "g2", g2Json)
        # 同步 nginx.conf  的 upstream 配置文件
        self.__sync_nginx_conf(serviceName, "g1", g1Json) 
        self.__sync_nginx_conf(serviceName, "g2", g2Json) 
        
        print "Sync service[", serviceName, "] done."
        LOGGER.debug("Sync service[%s] done.", serviceName)
        
    def __sync_nginx_luadict(self, serviceName):
        req = urllib2.Request("http://" + self.nginx_server["ip_port"] + "/bgpub/rule/set?service=" + serviceName)
        try:
            resp = urllib2.urlopen(req)
            if resp.code == 200:
                LOGGER.info("flush %s succeed.", serviceName)
            else:
                LOGGER.info("flush %s failed.", serviceName)
        except Exception as e:
            LOGGER.error("Network error when flush " + serviceName + ". msg: %s", e)
        
    # 同步 redis 数据到 nginx 线上缓存
    def __sync_nginx_upstream(self, serviceName, groupName, gJson):
        if gJson == None:
            LOGGER.debug("[__sync_nginx_upstream]: %s_%s is None.", serviceName, groupName)
            return
        
        redisServerDict = {}
        for k in gJson:
            if gJson.get(k) != None and gJson.get(k).find("down") < 0:
                redisServerDict[k] = gJson.get(k)
                
        resp = self.__query_upstream_servers(serviceName, groupName)
    # 根据 http 请求，得到 nginx 现有机器信息，包括 up & down 两种情况机器
        memServerDict = {}
        if resp.code == 200:
            resContent = resp.read()
            respArr = resContent.split(";")
            for i in range(len(respArr)):
                item = respArr[i].strip()
                if len(item) > 0:
                    itemArr = item.split(" ")
                    memServerDict[itemArr[1]] = item.find("down") > 0
        else:
            LOGGER.error("Query upstream[%s_%s] servers error %d", serviceName, groupName, resp.code) 
            
    # 两组 server 的key转为 set 进行处理
        memKeys = set(memServerDict.keys())
        redisKeys = set(redisServerDict.keys())
        
    # 循环 memKeys，将为 down的机器清除掉
    # 根据 server， 查看 nginx 的 server 是否为 down. 即： memServerDict.get(memServer) = true
    #    如果是 down, 首先调用 remove 接口删除，但如果是最后一台，会抛出异常。因为最后一台是 down 状态，则不做处理。
    #    如果非 down, 则加入集合，以后跟 redis 比较后决定是否删除
        memKeysNoDown = set()
        for memServer in memKeys:
            if memServerDict.get(memServer):  # down
                try:
                    resp = self.__upstream_action(serviceName, groupName, memServer, "remove")
                    del memServerDict[memServer]
                except Exception as e:
                    LOGGER.error("remove [%s] from [%s_%s] error. Exception: %s", memServer, serviceName, groupName, e) 
#                     print "remove [", memServer, "] from [", serviceName + "_" + groupName + "] error. Exception: ", e
            else:
                memKeysNoDown.add(memServer)  # up
      
    # 在线上，但不在 redis 队列里，表示要清除的机器
        memRemoveServer = memKeysNoDown.difference(redisKeys)
        if len(memRemoveServer) > 0:
            for removeServer in memRemoveServer:
                resp
                try:
                    resp = self.__upstream_action(serviceName, groupName, removeServer, "remove")
                except Exception as e:
                    LOGGER.error("remove [%s] from [%s_%s] error. Exception: %s", removeServer, serviceName, groupName, e) 
                    if e.code >= 400:
                        self.__upstream_action(serviceName, groupName, removeServer, "down") 
                        
    # 在 redis， 但不在  nginx 线上，表示要添加
        redisAddServer = redisKeys.difference(memKeysNoDown)
        if len(redisAddServer) > 0:
            for addServer in redisAddServer:
            # 因为最后一台机器为 down 时，是不包含在 memKeysNoDown. 故 redis 求差可能有最后一台 down 机器。这是不是 add, 是 up 操作
                if memServerDict.get(addServer):
                    self.__upstream_action(serviceName, groupName, addServer, "up")
                else:
                    self.__upstream_action(serviceName, groupName, addServer, "add")    

    # 同步 redis 数据到 nginx upstream.conf
    def __sync_nginx_conf(self, serviceName, groupName, gJson):
        if gJson == None:
            LOGGER.debug("[__sync_nginx_conf]: %s_%s is None.", serviceName, groupName)
            return
        ups_server = ""
        for k in gJson:
            ups_server = ups_server + "server " + " " + k + " " + gJson.get(k) + "\n"
        
        if len(ups_server) > 10:
            file_objectw = open(self.ups_conf["ups_file_path_prefix"] + serviceName + "_" + groupName + '.conf', 'wb')
            file_objectw.write(ups_server)
    
    # 初始化 redis              
    def __init_redis(self):
        pool = redis.ConnectionPool(host=self.redis_conf["host"], port=self.redis_conf["port"], db=self.redis_conf["db"], password=self.redis_conf["auth"])
        return redis.Redis(connection_pool=pool)    
    
    # 查询 upstream 所有 server 信息 
    def __query_upstream_servers(self, service, group):
        req = urllib2.Request("http://" + self.nginx_server["ip_port"] + "/dynamic?upstream=zone_" + service + "_" + group + "&verbose=")
        return urllib2.urlopen(req)
    
    # 动态修改 upstream 里 server 信息
    def __upstream_action(self, service, group, server, action):
        req = urllib2.Request("http://" + self.nginx_server["ip_port"] + "/dynamic?upstream=zone_" + service + "_" + group + "&verbose=&server=" + server + "&" + action + "=")
        return urllib2.urlopen(req)
    
    def get_upstreams(self):
        req = urllib2.Request("http://" + self.nginx_server["ip_port"] + "/bgpub/upstream/get?group=g1")
        return urllib2.urlopen(req)

# def doSync(p, NginxDict):
#     while True:
#         resp = p.get_upstreams()
#         if resp.code == 200:
#             resContent = resp.read()
#             print "ups: ", resContent
#             ups = json.loads(resContent)
#             serviceSet = set()
#             for k in ups:
#                 if len(k) > 0:
#                     serviceSet.add(k.split("_")[0])
#             
#             for k in serviceSet:
#                 print "sync :", k
#                 timer = threading.Timer(5, NginxDict.redis_sync_nginx, (p, {'sn':k}))
#                 timer.start()
#                 timer.join()
#         
#         else:
#             print "ups: ", type(resp)

# 构造定时轮询任务
def do_pool_sync(pool, p):
    if p != None:
        resp = p.get_upstreams()
        if resp.code == 200:
            resContent = resp.read()
            ups = json.loads(resContent)
            service_list = []
            for k in ups:
                if len(k) > 0:
                    service_list.append({'sn':k.split("_")[0]})
            requests = threadpool.makeRequests(p.redis_sync_nginx, service_list)
            [pool.putRequest(req) for req in requests]
            pool.wait()        
        else:
            LOGGER.error("No object to run the function.")
    timer = threading.Timer(5, do_pool_sync, (pool, p))
    timer.start() 
           
if __name__ == "__main__":
    p = NginxDict(111)
    pool = threadpool.ThreadPool(10)  
    timer = threading.Timer(1, do_pool_sync, (pool, p))
    timer.start() 
