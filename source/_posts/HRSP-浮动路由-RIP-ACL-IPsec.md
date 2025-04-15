---
title: HRSP-浮动路由-RIP-ACL-IPsec
tags:
  - HRSP
  - RIP
  - ACL
  - IPSec
categories:
  - - 安全技术
  - - 协议规范
description: 本文介绍了HRSP RIP ACL IPSec 的相关知识点
abbrlink: db738475
date: 2025-04-10 20:56:11
---

# 配置HSRP

R1(config)#int f0/0 //内网端口
R1(config-if)#standby 1 ip 虚拟ip地址
R1(config-if)#standby 1 priority 100
R1(config-if)# standby 1 preempt  //配置占先权
R1(config-if)# standby 1 times 2 8 //hello间隔与保持时间 同一hsrp组的时间应一致
R1(config-if)# standby 1 track f0/1 100 //配置端口跟踪
R1(config)# spanning-tree vlan 10 root primary
R1(config)# spanning-tree vlan 20 root secondary //配置生成树实现负载均衡vlan 20走备份路由
R2(config)#int f0/0 //内网端口
R2(config-if)#standby 1 ip 虚拟ip地址
R2(config-if)#standby 1 priority 195 //0-255
R2(config-if)# standby 1 preempt //设置活跃路由器得占先权，由于从较低优先级别得路由器中取回转发全，回复活跃路由器的角色
R2(config-if)# standby 1 times 2 8 //hello间隔与保持时间
R2(config-if)# standby 1 track f0/1 100 //配置端口跟踪
R2(config)# spanning-tree vlan 10 root primary
R2(config)# spanning-tree vlan 20 root secondary //配置生成树实现负载均衡vlan 20走备份路由
优先级高的路由其作为主路由，优先级低的路由作为备份路由，当主路由发生故障的时候，备份路由由监听状态切换到活跃状态。当优先级相同时，比较端口ip,ip较大的作为活跃路由，如果优先级低的路由
已经成为了活跃路由，那么优先级高的路由将作为监听路由，直到活跃路由发生故障。值愈大优先级越高

## hsrp协议组中由6种状态：

初始状态：路由器刚启动时，或者配置发生改变时
学习状态：路由其等待来自活跃路由器的消息，此时路由器还没有收到来自活跃里尤其的hello消息，也没有学习到虚拟路由器的ip地址
监听状态：路由其学习了虚拟的ip地址，但他既不是活跃路由器也不是监听路由器，此时负责监听来自活跃路由器与备份路由器的hello包
发言状态：路由器周期性发送hello消息，并参与活跃路由器或者备份路由器的京选
备份状态：处于该状态的路由器时下一个活跃路由器的候选设备，其周期性得发送hello包
活跃状态：负责转发虚拟路由器得数据包，并周期性得发送hello消息。
hello间隔：3s
保持间隔10s
通产保持间隔要在hello间隔得3倍
使用udp协议

## vrrp 虚拟路由冗余协议

只有初始状态、活跃状态、备份状态三种状态
允许vrrp组得设备间建立认证机制

# rip-距离矢量算法，根据跳数来选择路由

属于内部网关协议igp-有一系列协议族  还有一种时外部网关协议egp-只有一种协议
内部网关协议是往往是工作在一个组织实体里面的的路由器之间交换路由信息的协议，组织实体是指像学校、医院之类的实体
最大路由跳数为15跳，大于该值的路由被认为不可达

当更新周期到达时，其向相邻的路由器发送学习到的路由。

通过更行-update 与请求-requests两种分组来传输信息，更新周期为30s，如果不进行指定默认通过广播的形式更新信息。更新信息包括路由表与跳数两个部分。其并不是绝对根据跳数来选择路由的，同时也会参考网络的带宽。因为rip协议通过相邻路由器来更新路由表所以多网络全局的状况不清除，从而导致了一个慢收敛与不一致的问题。当三个火更多路由器构成环路是路由环路的问题仍会发生，这是需要用到触发更新法

RIP的水平分割

既路由器不向路径到来的方向回传此路径。通过将这些路由的跳数设置为16来实现该功能，能及时的解决路由环路的问题

RIP的保持定时器法

保持定时器可以防止路由器在路径从路由器从路由表中删除一定时间内（通常为180秒）接受新的路由信息。目的是为了保证每个路由器都收到路由不可达的信息，从而有效得避免了路由环路得产生。

RIP的触发更新法

当某个路径的跳数改变了路由器立即发生更新信息，不管路由器是否到达常规信息更新时间都发出更新信息。能够有效得加快路由的收敛时间

收敛机制

![](QQ20210329085323.png)

当主机与其直连路由器的链路发生中断时，其立刻向于其相邻的两个路由器发送路由更新信息，如果此时发送到右下路由器的信息发生堵塞延迟，则右上方的路由器先得到更新信息，将旧的到达主机的路由信息丢弃，右下方路由器因为没有收到来自左上路由器的更新信息，继续向右上路由器发送旧的路由信息，右上方路由器收到后又添加一条到达主机的路由。如此循环形成了路由环路。
使用udp协议的520端口

RIP帧格式

[RIP帧格式](RIP%E5%B8%A7%E6%A0%BC%E5%BC%8F%202019e93eb947495cbb98e4df2efa90c1.csv)

(config)#router rip
(config)#acc 1 deny any
(config-router)# network 接口网段
(config-router)# network 接口网段
(config-router)# passive-interface f0/1 //配置被动接口，只收不发
(config-router)# discribute-list 1 in f0/1 //配置路由过滤
(config-router)# distance 50 //配置管理距离值，该值越小路由信息越可靠
(config-router)# neigbor 192l.168.1.24 //配置邻居路由，以单播的形式发送路由信息

# 配置浮动路由

ip route 网段 掩码 下一跳地址|端口号 70
ip route 网段 掩码 下一跳地址|端口号 100 //最后一个参数位管理距离，其值越大表示优先级越低

# ACL

配置acl首先要配置内外网端口，配置过滤规则，将规则应用到端口。最后有一条默认拒绝所有。deny any

ACL包括标准acl 与扩展acl

标准acl是机与源ip地址进行过滤的 工作在三成 表号1-99

扩展acl可以通过端口号、协议等进行匹配过滤 国祚在三层与四层 表号 100-199

一个接口的一个方向只能有一张acl表，数据包一旦被某个rule匹配，就不再向下进行匹配。