# Require
* 灰度测试（流量控制）  
    根据请求（header, cookie, ip ...）信息控制该请求后续访问资源(upstream)  
    <b>关键点：</b> 线上请求无感知、性能损耗越小越好  
    
* 蓝绿上线（动态上线）  
    线上机器分两组，上线时借组两个组的概念可以保证线上服务不停机  
    <b>关键点：</b> 动态 upstream、流量在两组内自动切换  
    
# Design
  ### 针对HTTP请求，从入口开始改造，So 也就是Nginx 改造。   
  
   针对 nginx 的改造有两种途径：   
   <table>
    <tr bgcolor="#FF0000">
       <th>方法</th>
       <th>直接改动 nginx 源码</th>
       <th>Openresty 加 Lua 代码</th>
    </tr>
    <tr>
       <td>优点</td>
       <td>想干啥就干啥</td>
       <td>未改动Nginx代码，Nginx可以平滑升级</td>
    </tr>
    <tr>
       <td>缺点</td>
       <td>定制化Nginx，难以升级<br/>对C、网络、Nginx要非常熟练，技能要求高</td>
       <td>依赖 Openresty， 不少功能受限<br/>需掌握 Lua</td>
    </tr>
   </table>

   根据需求，考虑改造 Openresty 实现。
   
 ### 灰度测试改造思路
 ![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/gray_test.png)
 ![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/001_gray_test.jpg)
 
 ### 蓝绿上线
 ![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/002_gray_pub.jpg)
 ![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/003_gray_pub.jpg)
 ![image](https://github.com/qintianjie/blue-green-pub/blob/master/docs/pics/004_gray_pub.jpg)
  
# Sample
