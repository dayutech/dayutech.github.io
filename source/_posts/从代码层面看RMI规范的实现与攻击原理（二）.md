---
title: 从代码层面看RMI规范的实现与攻击原理（二）
tags:
  - RMI
  - 代码审计
categories:
  - - 漏洞分析
  - - 代码审计
description: 本文介绍了 从代码层面看RMI规范的实现与攻击原理
abbrlink: fa9410e3
date: 2025-04-14 10:33:52
---
@[TOC](从代码层面看RMI规范的实现与攻击原理（二）)

> 日常吐槽：这份工作确实无聊，不出活，没进步就是我上班的真实写照，学习进步还是要看下班后。

上一篇文章我们看了RMI客户端侧代码获取一个注册中心的操作，这一次我们来看看`lookup`函数是怎么工作的，有不对的地方大佬轻点喷。

在上一篇中我们知道最终获取到的`Registry`对象是由`RegistryImpl_Stub`不断转型过来的，那么使用该对象调用`lookup`函数理论上来说也就是会调用`RegistryImpl_Stub`中的`lookup`函数。
首先打断点进入到`lookup`函数：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/dbf896f525e005c3f49f93c2c2b39a37.png)
果然是调用的`RegistryImpl_Stub`中的函数，到这里前期我们有两个点需要关注一是116行，一是123行。
首先我们跟进116行的方法，这里调用的是`ref`对象的newCall，从名字我们大概猜到可能是要发送请求了，首先我们用wireshark过滤一下1099端口，然后让代码执行完116行：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e42dd5107e36f41ed2c10a2d30a4d1e2.png)
标记1处由客户端向注册中心发送请求，发送要使用的JRMI版本号，2处由注册中心向客户端确认版本号，至于第三处也是由客户端发起，具体干了什么我不太清楚（通过后面的分析我发现这一步应该也是类似于TCP三次握手那样的一个确认机制，注册中心返回自己的IP地址，然后客户端提取ip放到这个包里面，最后发送到注册中心，注册中心再对这次请求进行确认）：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/bafcbde8f4bf2a190f44ea70dd762b7a.png)
看这意思发送了一个ip地址过去，难道是协商要用哪一张网卡？？？？172这个ip还是我安装wsl的时候生成的一张虚拟网卡。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ea3ac57bee04b54eb242d352b48f3a4a.png)
看名字还是个虚拟以太网交换机？？这我就更迷惑了。。。不过暂时这不重要。
那么现在我们就进入到这个`newCall`方法中看一下都做了什么吧。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9c92b01fedcdad85dff58052275cec1a.png)
看到进入了`UnicastRef`这个类的中，这里注意第343行的代码，首先调用了`ref`对象的`getChannel`方法肯定是会返回一个对象的，然后再调用这个对象的`newConnection`方法，看着名字已经很清楚了这应该就是发送请求的关键函数了。`getChannel`不出意外是获取一个socket通道，然后`newConnection`方法发送请求，我们看看对不对，首先进入`getChannel`方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/71d465617ce4c4548e6106ec95aa4323.png)
看到进入了`LiveRef#getChannel`，这里大眼一瞧就注意到了第152行。调用了`ep`对象的`getChannel`方法，如果还记得上一篇的话，在获取注册中心的时候我们获得过一次`TCPEndpoint`对象然后赋值给了`ep`，这里就是了，`ep`中封装了注册中心的host与port：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d196277e2faec5a89a3d0d5a0b02b98b.png)
进入到`getChannel`方法：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/144f3de9286eb00c7507604db62c8f74.png)
果然来到了`TCPEndpoint`类。419行又是函数套函数，不过`getOutBoundTransport`应该是个类函数，翻译成中文就是获取对外绑定传输，强行翻译了一波。。。。从名字看不出来什么，进到函数里面看看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/9a6527244365840d5bfdb548e6b15259.png)
欧，又有，先看`getLocalEndpoint`函数吧，进去：
```java
public static TCPEndpoint getLocalEndpoint(int port,
                                               RMIClientSocketFactory csf,
                                               RMIServerSocketFactory ssf)
    {
        /*
         * Find mapping for an endpoint key to the list of local unique
         * endpoints for this client/server socket factory pair (perhaps
         * null) for the specific port.
         */
        TCPEndpoint ep = null;

        synchronized (localEndpoints) {
            TCPEndpoint endpointKey = new TCPEndpoint(null, port, csf, ssf);
            LinkedList<TCPEndpoint> epList = localEndpoints.get(endpointKey);
            String localHost = resampleLocalHost();

            if (epList == null) {
                /*
                 * Create new endpoint list.
                 */
                ep = new TCPEndpoint(localHost, port, csf, ssf);
                epList = new LinkedList<TCPEndpoint>();
                epList.add(ep);
                ep.listenPort = port;
                ep.transport = new TCPTransport(epList);
                localEndpoints.put(endpointKey, epList);

                if (TCPTransport.tcpLog.isLoggable(Log.BRIEF)) {
                    TCPTransport.tcpLog.log(Log.BRIEF,
                        "created local endpoint for socket factory " + ssf +
                        " on port " + port);
                }
            } else {
                synchronized (epList) {
                    ep = epList.getLast();
                    String lastHost = ep.host;
                    int lastPort =  ep.port;
                    TCPTransport lastTransport = ep.transport;
                    // assert (localHost == null ^ lastHost != null)
                    if (localHost != null && !localHost.equals(lastHost)) {
                        /*
                         * Hostname has been updated; add updated endpoint
                         * to list.
                         */
                        if (lastPort != 0) {
                            /*
                             * Remove outdated endpoints only if the
                             * port has already been set on those endpoints.
                             */
                            epList.clear();
                        }
                        ep = new TCPEndpoint(localHost, lastPort, csf, ssf);
                        ep.listenPort = port;
                        ep.transport = lastTransport;
                        epList.add(ep);
                    }
                }
            }
        }

        return ep;
    }

```

长的有点过粪了。。。。
看到函数中代码是异步执行的，这玩意儿我python中的异步都没咋搞清楚，更别说java了，但不影响我看代码。。。
首先new了一个`TCPEndpoint`类型的endpointkey，暂时不知道干什么的，然后调用了`localEndpoint`的get方法，看看`localEndpoint`是什么
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/467770a61828fca8946939daf24c16ac.png)
`Map`类型，键为`TCPEndpoint`类型，值为LinkedList集合类型。所以
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b31e77b96439a904f7ac83f2bce7a856.png)
201就是根据`endpointkey`从`Map`中 取值，然后202行调用`resampleLocalHost`方法对主机名进行重新采样，我猜就是再获取一下对host进行解析，不妨跟进去看一看：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/aea1a383e6ae368a46fbd0b5e75f6981.png)
257行获取了一个字符串，看命名应该是从properties中获取hostname，跟进`getHostnameProperty`函数看一下：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/da119bd40e9e12c28d3b358372a8135d.png)
这里有个`GetPropertyAction`类，上网查了一下粗糙的理解就是获取properties的值，进入函数看了看就是个赋值操作，不知道为甚么网上那样说。
最终的结论是`resampleLocalHost`方法还是返回了注册中心的IP地址，可能因为我这里在本地看不出来区别，分开的话应该就能判断出一些什么了。
然后回到`getLocalEndpoint`方法
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/e7a3fb0c0f7cbeb075727c3a33b65b2e.png)
又创建了一个`TCPEndpoint`对象，不过这时候有了主机名了localhost，一个`LinkedList`把新的`ep`放进去，然后又设置了一下ep的`listenport`属性，然后新建一个`TCPTransport`赋值给了`ep`的`transport`，真有趣，一个套一个。。。。最后返回了`ep`，一个`TCPEndpoint`对象。
然后抛出到`getOutboundTransport`方法又是这样的：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d49db9d235e7ceebf6abaecd40dd3cd1.png)
还是要的`transport`你说有趣不有趣。
依次往上抛，最终还是调用的`TCPTransport`对象的`getChannel`方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/276f048bb9549fc1de41ac6470cd007d.png)
这个`channelTable`又是一个`Map`![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/4b358d22fffa2030fdcd91d2c50fd03e.png)
一个端点对应一个TCP通道，很明显，我们还没有建立通道，所以这个表现在肯定是空的，所以在get的时候一是获取了个寂寞。
既然表示空的，下面的操作自然就是创建一个通道然后建立映射关系。然后返回这个通道，终于`getChannel`方法结束了，然后就是建立连接了，也就是调用`TCPChannel`对象的`newConnection`方法。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/22d3992d28378bcfb6ac6dd3fc0b294c.png)
代码挺长的，说白了就是看看是不是已经有了一个连接了，如果有了就直接拿来用，如果没有就新建一个，我们直接进到新建的逻辑里面：
```java
private Connection createConnection() throws RemoteException {
        Connection conn;

        TCPTransport.tcpLog.log(Log.BRIEF, "create connection");

        if (!usingMultiplexer) {
            Socket sock = ep.newSocket();
            conn = new TCPConnection(this, sock);

            try {
                DataOutputStream out =
                    new DataOutputStream(conn.getOutputStream());
                writeTransportHeader(out);

                // choose protocol (single op if not reusable socket)
                if (!conn.isReusable()) {
                    out.writeByte(TransportConstants.SingleOpProtocol);
                } else {
                    out.writeByte(TransportConstants.StreamProtocol);
                    out.flush();

                    /*
                     * Set socket read timeout to configured value for JRMP
                     * connection handshake; this also serves to guard against
                     * non-JRMP servers that do not respond (see 4322806).
                     */
                    int originalSoTimeout = 0;
                    try {
                        originalSoTimeout = sock.getSoTimeout();
                        sock.setSoTimeout(handshakeTimeout);
                    } catch (Exception e) {
                        // if we fail to set this, ignore and proceed anyway
                    }

                    DataInputStream in =
                        new DataInputStream(conn.getInputStream());
                    byte ack = in.readByte();
                    if (ack != TransportConstants.ProtocolAck) {
                        throw new ConnectIOException(
                            ack == TransportConstants.ProtocolNack ?
                            "JRMP StreamProtocol not supported by server" :
                            "non-JRMP server at remote endpoint");
                    }

                    String suggestedHost = in.readUTF();
                    int    suggestedPort = in.readInt();
                    if (TCPTransport.tcpLog.isLoggable(Log.VERBOSE)) {
                        TCPTransport.tcpLog.log(Log.VERBOSE,
                            "server suggested " + suggestedHost + ":" +
                            suggestedPort);
                    }

                    // set local host name, if unknown
                    TCPEndpoint.setLocalHost(suggestedHost);
                    // do NOT set the default port, because we don't
                    // know if we can't listen YET...

                    // write out default endpoint to match protocol
                    // (but it serves no purpose)
                    TCPEndpoint localEp =
                        TCPEndpoint.getLocalEndpoint(0, null, null);
                    out.writeUTF(localEp.getHost());
                    out.writeInt(localEp.getPort());
                    if (TCPTransport.tcpLog.isLoggable(Log.VERBOSE)) {
                        TCPTransport.tcpLog.log(Log.VERBOSE, "using " +
                            localEp.getHost() + ":" + localEp.getPort());
                    }

                    /*
                     * After JRMP handshake, set socket read timeout to value
                     * configured for the rest of the lifetime of the
                     * connection.  NOTE: this timeout, if configured to a
                     * finite duration, places an upper bound on the time
                     * that a remote method call is permitted to execute.
                     */
                    try {
                        /*
                         * If socket factory had set a non-zero timeout on its
                         * own, then restore it instead of using the property-
                         * configured value.
                         */
                        sock.setSoTimeout((originalSoTimeout != 0 ?
                                           originalSoTimeout :
                                           responseTimeout));
                    } catch (Exception e) {
                        // if we fail to set this, ignore and proceed anyway
                    }

                    out.flush();
                }
            } catch (IOException e) {
                try {
                    conn.close();
                } catch (Exception ex) {}
                if (e instanceof RemoteException) {
                    throw (RemoteException) e;
                } else {
                    throw new ConnectIOException(
                        "error during JRMP connection establishment", e);
                }
            }
        } else {
            try {
                conn = multiplexer.openConnection();
            } catch (IOException e) {
                synchronized (this) {
                    usingMultiplexer = false;
                    multiplexer = null;
                }
                throw new ConnectIOException(
                    "error opening virtual connection " +
                    "over multiplexed connection", e);
            }
        }
        return conn;
    }
```
这一段代码就长的有点离大谱了，主要关注两个`out.flush`就是这行代码发起了请求，前面都是些前戏。。。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/b7ce319853f0a81f9b6423e73422a923.png)
216与217行的代码已经很清楚了，新建一个socket，然后进行TCP连接，也就是进行三次握手，217执行完毕后，我们就可以使用wireshark看到：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ac74b906c3c7167d461247f0e5910147.png)
妥妥的握手报文。
然后就是创建一个使用`conn`创建一个输出流，然后将其封装为数据输出流，然后再为输出流设置JRMI幻数与版本：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/5d128b917e925efdae34ee1ccde566ad.png)
看一下协议幻数与版本号分别是多少：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/d5ea58732ddac83242ae8649d58cf580.png)

然后判断连接是否可重用，嗯，我看过了，是可重用的，所以又给输出流写了`TransportConstants.StreamProtocol`，这个值为`0x4b`
这个编号我还好奇去转了一下码：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c21e1dc5f77996f14dd88261428f5953.png)
然后我去查了一下协议号：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/33435cfb0a4de3e39f01e53c38da88ea.png)
这75是个什么鬼。。。对不上啊，只能解释为这两不是一个概念了。。。嗯，肯定不是一个概念，在`out.flush`发包后，我们看看看wireshark抓到的包：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/c85f4ddc3b459144609138ebcdd56296.png)
看红框里面的16进制值为`4a524d4900024b`，就是协议幻数+版本号+流协议标识，知道了这个，我们就有了伪造RMI协议的第一个关键信息了。。。。。
看看对响应的处理：
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/fefe420814025b84e8d9a10f36c5b8aa.png)
首先封装了一个`DataInputStream`流对象，然后从输入流里面读了1个字节出来作为协议确认码ack，此处为`78`,然后判断ack是否等于`TransportConstants.ProtocolAck`，即`0x4e`，翻译为十进制就是78，这里是相等的。
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/1818e586dbb2a51d0291e31e5fdf1f7e.png)
然后继续读输入流得到`suggestedHost`与`suggestedPort`
然后设置`TCPEndpoint`的host为获取到的`suggestedHost`，`localhost`也为获取到的`suggestedHost`，然后创建一个本地端点，通过这个端点获取主机与端口设置给输出流，然后out.flush将缓冲区的数据发送出去，通过wireshark抓包
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/ff74eef65b4fdf5f6aad80a54a0bd84e.png)
看到这里发送的请求报文中确实有ip地址，但是没有看到端口啊，哪里除了问题？
![在这里插入图片描述](https://i-blog.csdnimg.cn/blog_migrate/a3402e3f023d26c3aa3f42a79ae037dd.png)
注意到这儿获取本地端点的时候传入的端口就是0，抓包看到的请求为0也算正常。
这里就获取到了伪造RMI协议的第二个关键数据。。。。。这是越来越刑啊。。。。。

总之到目前为止，发送RMI请求的连接已经获取完毕的，接下来的工作就是客户端携带要查询的key去注册中心查询是否存在对应的对象，然后注册中心将返回一个存根给客户端，然后客户端利用这个存根再去访问服务器的skeleton，服务器骨架访问服务器查看是否存在这样一个方法，根据客户端发送过来的方法名与参数执行对应的方法，然后将执行的结果返回给客户端由客户端存根接收然后转发给客户端。
好了今天时间比较晚了，预知后事如何，请听下回分解。。。。
