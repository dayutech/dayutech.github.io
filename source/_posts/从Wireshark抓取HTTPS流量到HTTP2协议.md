---
title: 从Wireshark抓取HTTPS流量到HTTP2协议
date: 2025-04-14 10:33:52
tags:
- wireshark
- https
- http2
categories:
  - [协议规范]
---
# 吹水
打工人今天正无聊在小蓝鸟上看看国外的大哥们最近有没有又搞什么大动作，突然看到一条推文介绍使用wireshark抓取https报文的方法，正好前段时间也在公众号看到了一篇文章教这个，当时配置好了但没有去实际验证过好使不，于是趁着上班时间不验证白不验证，我这不是划水，我这是在打造生产工具，为下一步提升生产力打下良好的基础。
配置其实相对来说还是很简单的，首先是需要设置一下环境变量增加一项SSLKEYLOGFILE指向一个文本文件就好了，这样谷歌或者火狐浏览器在运行的时候就会将每次https会话的加密秘钥存储在这个文件里面，然后再wireshark中配置一下TLS协议的认证文件也指向这个文件就ok了，当然这个原理是我自己理解的，不过想来也就八九不离十了。想要知道详情的可以参看下面两篇文章咯
> [https://mp.weixin.qq.com/s/jUFT1iA6Uy7EKJAFkebjDw](https://mp.weixin.qq.com/s/jUFT1iA6Uy7EKJAFkebjDw)
> [https://twitter.com/binitamshah/status/1511254916484198402?s=20&t=qrF9mz6muHovokRB5nGPkg](https://twitter.com/binitamshah/status/1511254916484198402?s=20&t=qrF9mz6muHovokRB5nGPkg)
<!--more-->
最终的实现效果是这样的
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/da6b1188291a0cb3faaa42a16cb0f24a.png)
看到这里我陷入了疑问，平时我们用burp抓的包都是HTTP1.1版本的，怎么到了wireshark这里之后就变成HTTP2版本的了，于是我使用有道翻译做了个实验。首先使用Burp抓包然后再发包使用wireshark抓包之后发现报文还是正常的HTTP1.1版本的，在wireshark中使用HTTP2协议过滤器捕获不到这部分流量，当我直接使用浏览器访问时却是能后正常使用http2协议过滤器看到这些报文，据说是有HTTP协议协商机制
> [https://cloud.tencent.com/developer/article/1420299](https://cloud.tencent.com/developer/article/1420299)

当看到这个wireshark抓到的http协议流量的时候我来了兴趣，于是去学习了一下HTTP2协议的知识。
HTTP2协议相比于HTTP1.1协议有很大的不同，首先2版本的协议使用的是字节来传输数据而不是文本，其次2版本的协议是双向的协议，这主要得益于服务端推送机制，然后2版本的协议是没有阻塞与等待的可以并行的发送多个请求，再有2版本的协议一个域名就是一个连接，不像1版本的协议一次请求就是一次新的连接，这极大的节约了资源，提高了效率，再有就是头部压缩算法，鉴于1版本协议每次请求都需要发送大量的重复的头信息，2版本在这方面进行了优化。
# HTTP2协议简介
详情可参考这篇文章
> [https://www.jianshu.com/p/e57ca4fec26f](https://www.jianshu.com/p/e57ca4fec26f)
## 简介
在HTTP2中有几个关键词，帧、请求、流、连接。一个请求就是一个流，一个流由多个帧组成，一个域名一个连接，一个连接里有多个请求。不同流的帧是可以同时并发请求的，但是同一个流中的帧是有严格的顺序的，客户端请求一个页面可能需要发送多次请求，在HTTP2中因为服务端推送的存在可以减轻客户端请求的压力，只需一次请求服务端可以主动向服务端推送需要的配套资源，当然客户端如果缓存没有过期等还可以拒收。
HTTP2协议的单独的一个帧有统一的格式。包括固定9字节的帧头以及负载也就是数据部分。
在帧头中包括帧长（24）帧类型（8）标志位（8）R（1保留位）帧ID（31位）
其中标志位的格式取决于帧类型。
## 帧类型
帧类型包括
| 帧类型 | 中文 |含义|
|--|--|--|
| HEADERS | 报头帧 (type=0x1)  |用来打开一个流或者携带一个首部块片段，基本就相当于1.1版本的请求头部分|
| DATA | 数据帧 (type=0x0)  |装填主体信息，可以用一个或多个 DATA 帧来返回一个请求的响应主体|
| PRIORITY | 优先级帧 (type=0x2) |指定发送者建议的流优先级，可以在任何流状态下发送 PRIORITY 帧，包括空闲 (idle) 和关闭 (closed) 的流|
| RST_STREAM | 流终止帧 (type=0x3)  |流终止帧 (type=0x3)，用来请求取消一个流，或者表示发生了一个错误，payload 带有一个 32 位无符号整数的错误码 (Error Codes)，不能在处于空闲 (idle) 状态的流上发送 RST_STREAM 帧|
| SETTINGS | 设置帧 (type=0x4) |设置此 连接 的参数，作用于整个连接，一般是一次连接的第一个帧，当然前面的协议前言不算的话|
|PUSH_PROMISE  | 推送帧 (type=0x5) |服务端推送，客户端可以返回一个 RST_STREAM 帧来选择拒绝推送的流|
| PING | PING 帧 (type=0x6) |判断一个空闲的连接是否仍然可用，也可以测量最小往返时间 (RTT)|
| GOAWAY | GOWAY 帧 (type=0x7) |用于发起关闭连接的请求，或者警示严重错误。GOAWAY 会停止接收新流，并且关闭连接前会处理完先前建立的流|
| WINDOW_UPDATE  |窗口更新帧 (type=0x8)  |用于执行流量控制功能，可以作用在单独某个流上 (指定具体 Stream Identifier) 也可以作用整个连接 (Stream Identifier 为 0x0)，只有 DATA 帧受流量控制影响。初始化流量窗口后，发送多少负载，流量窗口就减少多少，如果流量窗口不足就无法发送，WINDOW_UPDATE 帧可以增加流量窗口大小|
| CONTINUATION |延续帧 (type=0x9)  |用于继续传送首部块片段序列|

## DATA帧
DATA帧的payload部分已8位的填充长度开头，然后是正式的数据部分，最后根据填充长度字段指定的长度在末尾填充对应数量的0
看一下实际的帧
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/fbb55e776451089a2079bcc7e3b4523b.png)
可以看到DATA帧的标志位分成了三部分分别为保留位、填充标志、是否为当前流的结束包三个字段
## HEADERS帧
同样的HEADERS帧也是以8位填充长度字段开头，然后是1位的流依赖申明，31位的依赖流ID、8位的优先级、压缩头部、填充值
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/f400f0bb602346560e078f4bca820ca1.png)
标志位包括保留位、优先级标识、填充标识、是否为当前流的最后一个头部包、是否为当前流的最后一个包
## SETTINGS 帧
SETTINGS帧的就包括两部分分别为设置项ID以及其值
设置项一般包含一下项目
|设置项|ID|解释|
|---|--|--|
|SETTINGS_HEADER_TABLE_SIZE|0x1|用于解析 Header block 的 Header 压缩表的大小，初始值是 4096 字节|
|SETTINGS_ENABLE_PUSH|0x2|可以关闭 Server Push，该值初始为 1，表示允许服务端推送功能|
|SETTINGS_MAX_CONCURRENT_STREAMS|0x3|代表发送端允许接收端创建的最大流数目|
|SETTINGS_INITIAL_WINDOW_SIZE|0x4|指明发送端所有流的流量控制窗口的初始大小，会影响所有流，该初始值是 2^16 - 1(65535) 字节，最大值是 2^31 - 1，如果超出最大值则会返回 FLOW_CONTROL_ERROR|
|SETTINGS_MAX_FRAME_SIZE|0x5|指明发送端允许接收的最大帧负载的字节数，初始值是 2^14(16384) 字节，如果该值不在初始值 (2^14) 和最大值 (2^24 - 1) 之间，返回 PROTOCOL_ERROR|
|SETTINGS_MAX_HEADER_LIST_SIZE |0x6|通知对端，发送端准备接收的首部列表大小的最大字节数。该值是基于未压缩的首部域大小，包括名称和值的字节长度，外加每个首部域的 32 字节的开销|

![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/6c1518eb180419c56d1cde1f8f3c1325.png)
标志位就ACK比较重要，这个标识位是在收到对端发送的SETTINGS帧时向对端回复时设置的，用以确认已收到报文。
然后一次完整的连接过程是以Magic帧开头GOAWAY帧结尾的，但在我观察实际流量时发现却没有GOAWAY帧


